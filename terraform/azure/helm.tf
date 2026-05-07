resource "helm_release" "argocd" {
  name       = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.2.3"
  values     = [file("${path.module}/helm/argocd-values.yaml")]
  atomic     = true
  wait       = true
  timeout    = 900

  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "helm_release" "argocd_image_updater" {
  name       = "argocd-image-updater"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = "1.1.5"
  values = [
    templatefile("${path.module}/helm/argocd-image-updater-values.yaml", {
      acr_login_server = azurerm_container_registry.this.login_server
    })
  ]
  atomic  = true
  wait    = true
  timeout = 600

  depends_on = [
    kubernetes_namespace_v1.argocd,
    helm_release.argocd
  ]
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.14.0"
  values     = [file("${path.module}/helm/ingress-nginx-values.yaml")]
  atomic     = true
  wait       = true
  timeout    = 900

  depends_on = [kubernetes_namespace_v1.ingress_nginx]
}
