#!/bin/bash -e
#Running root

# install vault
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install vault

# install jq
yum install -y jq

# env setting
INSTANCE_ID=$(curl -fs http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -fs http://169.254.169.254/latest/meta-data/local-ipv4)
# LB_DOMAIN="${LB_DOMAIN}"
# AWS_REGION="${AWS_REGION}"
# KMS_KEY="${KMS_KEY}"

# vault env setting
cat << EOF >> ~/.bashrc
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true
complete -C /usr/bin/vault vault
EOF

source ~/.bashrc


# create vault raft dir
mkdir -p /vault/raft
chown -R vault.vault /vault/raft

# create vault config file
cat << EOF > /etc/vault.d/vault.hcl
storage "raft" {
  path    = "/vault/raft"
  node_id = "node_$${INSTANCE_ID}"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = "true"
}

seal "awskms" {
  region = "${AWS_REGION}"
  kms_key_id = "${KMS_KEY}"
}

api_addr = "http://${LB_DOMAIN}:8200"
cluster_addr = "http://$${PRIVATE_IP}:8201"
disable_mlock = true
ui = true
EOF

systemctl daemon-reload

# change owner
chown -R vault.vault /etc/vault.d
chown -R vault.vault /vault

# start vault
systemctl enable vault
systemctl restart vault

echo "--- Vault Install Complete ---"

if [[ $PRIVATE_IP == "${LEADER_IP}" ]]
then
	# first init vault for leader
	vault operator init > /etc/vault.d/vault_key.txt
	root_token=$(cat /etc/vault.d/vault_key.txt | awk '{ if (match($0,/Initial Root Token: (.*)/,m)) print m[1] }'  | cut -d " " -f 1)
	vault login $root_token
	echo "--- Vault Leader ---"

else
	# init vault for follower
	LEADER_IP=${LEADER_IP}

	# Initialize the counter
	counter=0

	# Wait until the leader is ready or the counter exceeds the limit
	while true; do
		if curl --silent --fail http://$LEADER_IP:8200/v1/sys/health | grep -q '"initialized":true'; then
			break
		else
			# Increase the counter
			counter=$((counter + 1))

			# If the counter exceeds the limit, exit the loop
			if [[ $counter -gt 60 ]]; then
				echo "The leader did not become ready within the expected time."
				exit 1
			fi

			echo "Waiting for the leader to be ready..."
			sleep 5
		fi
	done
	
	vault operator raft join http://$LEADER_IP:8200
	echo "--- Vault Follower ---"
fi