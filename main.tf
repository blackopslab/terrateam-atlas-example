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

resource "aws_security_group" "rds" {
  name   = "terrateam"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a DB subnet group using default VPC subnets
resource "aws_db_subnet_group" "terrateam" {
  name       = "terrateam"
  subnet_ids = data.aws_subnets.default.ids
}

# Create a RDS PostgreSQL instance
resource "aws_db_instance" "terrateam" {
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  identifier           = "terrateam"
  parameter_group_name = "default.mysql8.0"
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.terrateam.name
  skip_final_snapshot  = true
  # database is publicly accessible, don't do this in prod!
  publicly_accessible  = true
}

# Atlas provider configuration
provider "atlas" {
}

# Load schema from HCL file
data "atlas_schema" "terrateam" {
  dev_url = "mysql://${var.db_username}:${var.db_password}@${aws_db_instance.terrateam.address}:3306/"
  src = file("${path.module}/schema.hcl")
  depends_on = [aws_db_instance.terrateam]
}

# Sync target state with HCL file
resource "atlas_schema" "terrateam" {
  hcl = data.atlas_schema.terrateam.hcl
  url = "mysql://${var.db_username}:${var.db_password}@${aws_db_instance.terrateam.address}:3306/"
  depends_on = [aws_db_instance.terrateam]
}