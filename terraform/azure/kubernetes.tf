resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_secret_v1" "argocd_repository" {
  count = var.github_gitops_token == "" ? 0 : 1

  metadata {
    name      = "repo-${var.github_gitops_repo}"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    type     = "git"
    url      = var.github_gitops_repo_url
    username = var.github_gitops_username
    password = var.github_gitops_token
  }
}

resource "kubernetes_secret_v1" "acr_regcred" {
  metadata {
    name      = "regcred"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (azurerm_container_registry.this.login_server) = {
          username = azurerm_container_registry_token.pull.name
          password = azurerm_container_registry_token_password.pull.password1[0].value
          auth     = base64encode("${azurerm_container_registry_token.pull.name}:${azurerm_container_registry_token_password.pull.password1[0].value}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "kubectl_manifest" "applicationsets" {
  for_each = var.install_demo_applicationsets ? fileset("${path.module}/../../gitops-repo/applicationsets", "*.yaml") : toset([])

  yaml_body = replace(
    file("${path.module}/../../gitops-repo/applicationsets/${each.value}"),
    "https://github.com/diploma-devops-lab/diploma-gitops-repo.git",
    var.github_gitops_repo_url
  )

  depends_on = [
    helm_release.argocd,
    helm_release.argocd_image_updater,
    kubernetes_secret_v1.argocd_repository,
    kubernetes_secret_v1.acr_regcred
  ]
}
