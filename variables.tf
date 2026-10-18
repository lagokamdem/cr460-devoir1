variable "location" {
  description = "Région Azure"
  type        = string
  default     = "canadacentral"
}

variable "prefix" {
  description = "Préfixe des noms de ressources"
  type        = string
  default     = "cr460"
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources"
  type        = map(string)
  default = {
    Projet = "DevoirCR460"
  }
}

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Utilisateur administrateur de la VM"
  type        = string
  default     = "azureuser"
}