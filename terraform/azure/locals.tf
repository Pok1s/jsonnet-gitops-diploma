locals {
  name_prefix         = "${var.project}-${var.environment}"
  resource_group_name = "rg-${local.name_prefix}"
  aks_name            = "aks-${local.name_prefix}"
  vnet_name           = "vnet-${local.name_prefix}"
  github_repo_full    = "${var.github_owner}/${var.github_app_repo}"
  gitops_repo_full    = "${var.github_owner}/${var.github_gitops_repo}"

  tags = {
    project     = var.project
    environment = var.environment
    managedBy   = "terraform"
    purpose     = "diploma-demo"
  }
}

