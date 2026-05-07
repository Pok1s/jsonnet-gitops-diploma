output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "acr_login_server" {
  value = azurerm_container_registry.this.login_server
}

output "github_actions_client_id" {
  value = azuread_application.github_actions.client_id
}

output "github_actions_tenant_id" {
  value = var.tenant_id
}

output "github_actions_subscription_id" {
  value = var.subscription_id
}

output "github_actions_repository_variables" {
  value = {
    ACR_NAME           = azurerm_container_registry.this.name
    ACR_LOGIN_SERVER   = azurerm_container_registry.this.login_server
    GITOPS_REPOSITORY  = local.gitops_repo_full
    GH_OWNER           = var.github_owner
    GH_APP_REPO        = var.github_app_repo
    GH_GITOPS_REPO     = var.github_gitops_repo
    GH_GITOPS_REPO_URL = var.github_gitops_repo_url
  }
}

output "kubeconfig_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name} --admin"
}
