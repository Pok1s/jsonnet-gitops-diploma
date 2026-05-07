resource "azuread_application" "github_actions" {
  display_name = "${local.name_prefix}-github-actions"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_application_federated_identity_credential" "github_branches" {
  for_each       = toset(["main", "develop"])
  application_id = azuread_application.github_actions.id
  display_name   = "github-${each.key}"
  description    = "GitHub Actions OIDC for ${local.github_repo_full} ${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo_full}:ref:refs/heads/${each.key}"
}

resource "azuread_application_federated_identity_credential" "github_environments" {
  for_each       = toset(["dev", "stage", "prod", "azure-plan", "azure-apply", "azure-destroy"])
  application_id = azuread_application.github_actions.id
  display_name   = "github-env-${each.key}"
  description    = "GitHub Actions OIDC for ${local.github_repo_full} environment ${each.key}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.github_repo_full}:environment:${each.key}"
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "azurerm_role_assignment" "github_subscription_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
