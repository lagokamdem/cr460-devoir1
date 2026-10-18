terraform {
  required_version = ">= 1.16.0"

  cloud {
    organization = "lagokamdem-cr460"
    workspaces {
      name = "cr460-devoir1"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}