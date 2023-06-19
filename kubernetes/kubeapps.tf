# Gitlab
resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "http://charts.gitlab.io/"
  chart      = "gitlab"
  version    = "7.0.3"
  namespace  = kubernetes_namespace.gitlab.metadata[0].name
  timeout    = 900

  values = [
    "${file("./helm_values/gitlab.yaml")}"
  ]

  depends_on = [
    module.eks_common,
    module.eks_addon
  ]
}