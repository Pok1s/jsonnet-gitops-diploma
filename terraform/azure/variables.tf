variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "project" {
  type    = string
  default = "diploma-gitops"
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "github_owner" {
  type    = string
  default = "diploma-devops-lab"
}

variable "github_app_repo" {
  type    = string
  default = "diploma-demo-web"
}

variable "github_gitops_repo" {
  type    = string
  default = "diploma-gitops-repo"
}

variable "github_gitops_repo_url" {
  type    = string
  default = "https://github.com/diploma-devops-lab/diploma-gitops-repo.git"
}

variable "github_gitops_username" {
  type    = string
  default = "git"
}

variable "github_gitops_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "acr_name" {
  type    = string
  default = "pok1sdiplomaacr"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must be globally unique, alphanumeric and 5-50 characters."
  }
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "aks_system_node_count" {
  type    = number
  default = 2
}

variable "aks_system_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "admin_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "install_demo_applicationsets" {
  type    = bool
  default = true
}
