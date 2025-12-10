# Configuración del proveedor (AWS, Azure o GCP)
# infra/provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Asegúrate de usar la región que te funcione mejor
  region = "us-east-1" 
}