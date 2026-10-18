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
  default     = "Standard_B2pts_v2"
}

variable "admin_username" {
  description = "Utilisateur administrateur de la VM"
  type        = string
  default     = "azureuser"
}

variable "admin_object_id" {
  description = "Object ID de l'utilisatrice autorisée à lire les secrets du Key Vault"
  type        = string
  default     = "ae106343-afa4-4612-81b4-c1797c0e9785"
}