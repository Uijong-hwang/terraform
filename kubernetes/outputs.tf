output "update_kubeconfig_command" {
  description = "생성된 EKS 클러스터에 사용할 kubeconfig 파일 생성 명령어"
  value       = module.eks.update_kubeconfig_command
}