terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Terraform 1.11 introduced write-only attributes, required for secret_string_wo
  required_version = ">= 1.11"
}
