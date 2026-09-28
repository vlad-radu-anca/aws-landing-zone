terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # S3 native state locking (use_lockfile) replaces the DynamoDB table that
  # older setups needed. Available from Terraform 1.10.
  backend "s3" {
    key          = "landing-zone/organization/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Terraform = "true"
      Project   = "asgard"
      Component = "landing-zone"
    }
  }
}
