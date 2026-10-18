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

# Étape 9 - Machine virtuelle
resource "random_password" "vm" {
  length           = 20
  special          = true
  override_special = "!@#%*()-_=+"
}

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
  admin_password                  = random_password.vm.result
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