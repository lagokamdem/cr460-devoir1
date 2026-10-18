data "azurerm_client_config" "current" {}

# Étape 7 - Groupe de ressources
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}-devoir1"
  location = var.location
  tags     = var.tags
}

# Étape 8 - Réseau virtuel
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-${var.prefix}-vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Étape 12 - Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.prefix}-lagokamdem"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  rbac_authorization_enabled = false
  tags                       = var.tags

  # Accès pour l'identité managée utilisée par Terraform
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }

  # Accès en lecture pour l'utilisatrice (portail Azure)
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = var.admin_object_id
    secret_permissions = ["Get", "List"]
  }
}

resource "random_password" "vm" {
  length           = 20
  special          = true
  override_special = "!@#%*()-_=+"
}

resource "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  value        = random_password.vm.result
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "Mot de passe administrateur de vm-cr460"
  tags         = var.tags
}

# Étape 9 - Machine virtuelle
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.prefix}-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-${var.prefix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = azurerm_key_vault_secret.vm_password.value
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic.id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }
}

# Étape 14 - Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acr${var.prefix}lagokamdem"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

# Étape 10 - Container Docker (Azure Container Instances)
resource "azurerm_container_group" "aci" {
  name                = "aci-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-lagokamdem"
  tags                = var.tags

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  container {
    name   = "cr460-app"
    image  = "${azurerm_container_registry.acr.login_server}/cr460-app:latest"
    cpu    = 0.5
    memory = 1.0

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

output "container_url" {
  value = "http://${azurerm_container_group.aci.fqdn}"
}