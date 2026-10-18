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