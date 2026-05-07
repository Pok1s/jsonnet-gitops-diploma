resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.42.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.42.1.0/24"]
}

resource "azurerm_container_registry" "this" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

resource "azurerm_container_registry_scope_map" "pull" {
  name                    = "diploma-demo-pull"
  container_registry_name = azurerm_container_registry.this.name
  resource_group_name     = azurerm_resource_group.this.name

  actions = [
    "repositories/*/content/read",
    "repositories/*/metadata/read"
  ]
}

resource "azurerm_container_registry_token" "pull" {
  name                    = "diploma-demo-pull"
  container_registry_name = azurerm_container_registry.this.name
  resource_group_name     = azurerm_resource_group.this.name
  scope_map_id            = azurerm_container_registry_scope_map.pull.id
}

resource "azurerm_container_registry_token_password" "pull" {
  container_registry_token_id = azurerm_container_registry_token.pull.id

  password1 {
    expiry = timeadd(timestamp(), "8760h")
  }

  lifecycle {
    ignore_changes = [password1[0].expiry]
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = local.aks_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = replace(local.aks_name, "-", "")
  kubernetes_version  = var.kubernetes_version

  sku_tier               = "Free"
  local_account_disabled = false

  api_server_access_profile {
    authorized_ip_ranges = var.admin_cidr_blocks
  }

  default_node_pool {
    name                        = "system"
    vm_size                     = var.aks_system_vm_size
    node_count                  = var.aks_system_node_count
    vnet_subnet_id              = azurerm_subnet.aks.id
    temporary_name_for_rotation = "sysrot"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.20.0.0/16"
    dns_service_ip    = "172.20.0.10"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = local.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
