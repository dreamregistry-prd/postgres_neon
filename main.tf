terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.5"
    }

    neon = {
      source = "kislerdm/neon"
      version = "~> 0.6.3"
    }
  }
}

provider "aws" {}
provider "random" {}
provider "neon" {}

data "aws_region" "current" {}

resource "random_string" "random" {
  length  = 16
  special = false
  upper   = false
}

resource "neon_project" "project" {
  name = random_string.random.result
  region_id = var.region
  history_retention_seconds = 86400
}

resource "aws_ssm_parameter" "connection_uri" {
  name = "/${neon_project.project.name}/connection_uri"
  type = "SecureString"
  value = neon_project.project.connection_uri
}


output "POSTGRES_URL" {
  value = {
    type   = "ssm"
    key    = aws_ssm_parameter.connection_uri.name
    region = data.aws_region.current.name
    arn    = aws_ssm_parameter.connection_uri.arn
  }
}

output "DB_NAME" {
  value = neon_project.project.database_name
}
