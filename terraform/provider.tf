terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["$HOME/.aws/credentials"]

  default_tags {
    tags = {
      Company   = "Transportes Flores Vargas"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
