terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Buena práctica: Estado remoto en S3
  backend "s3" {
    bucket = "pl-sales-terraform-state"
    key    = "app/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Repositorio para la imagen de Docker
resource "aws_ecr_repository" "sales_api_repo" {
  name                 = "pl-sales-api-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true # Seguridad: Escaneo de vulnerabilidades
  }
}

# 2. Servicio App Runner para despliegue serverless del contenedor
resource "aws_apprunner_service" "sales_api_service" {
  service_name = "pl-sales-api-svc-${var.environment}"

  source_configuration {
    image_repository {
      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          SPRING_PROFILES_ACTIVE = var.environment
        }
      }
      image_identifier      = "${aws_ecr_repository.sales_api_repo.repository_url}:latest"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = true
  }
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

output "app_url" {
  value = aws_apprunner_service.sales_api_service.service_url
}
