# Install the Atlas and AWS providers
terraform {
  required_providers {
    atlas = {
      source = "ariga/atlas"
      version = "~> 0.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terrateam-atlas"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

# AWS provider configuration
provider "aws" {
  region = "eu-west-1"
}

variable "db_username" {
  description = "Master username for the RDS database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS database"
  type        = string
  sensitive   = true
}

/* Since we are not in production, we will skip a more methodic
VPC / Subnet and Security Group configuration and use Terraform
to fetch the existing default VPC. */

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

