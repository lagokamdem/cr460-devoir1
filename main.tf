resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}-devoir1"
  location = var.location
  tags     = var.tags
}