# Basic ECR Repositories Example
# This example creates multiple ECR repositories with different configurations

terraform {
  required_version = ">= 1.12.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ECR Module
module "ecr" {
  source = "../../"

  repositories = var.repositories

  # Default settings for all repositories
  default_image_tag_mutability           = var.default_image_tag_mutability
  default_force_delete                   = var.default_force_delete
  default_scan_on_push                  = var.default_scan_on_push
  default_encryption_type               = var.default_encryption_type
  default_kms_key                       = var.default_kms_key

  # Lifecycle policy settings
  enable_default_lifecycle_policy          = var.enable_default_lifecycle_policy
  default_lifecycle_policy_max_image_count = var.default_lifecycle_policy_max_image_count
  default_lifecycle_policy_untagged_days  = var.default_lifecycle_policy_untagged_days

  # Registry-level configuration
  enable_registry_scanning = var.enable_registry_scanning
  registry_scan_type      = var.registry_scan_type
  registry_scanning_rules = var.registry_scanning_rules

  # Replication (disabled in basic example)
  enable_replication = false

  tags = var.tags
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "repositories" {
  description = "Map of ECR repository configurations"
  type        = any
  default = {
    "my-web-app" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push        = true
      force_delete        = false
      encryption_type     = "AES256"
      kms_key            = null
      repository_policy  = null
      lifecycle_policy   = null
      repository_type    = "private"
      tags = {
        Application = "web-app"
        Tier        = "frontend"
      }
    }
    
    "my-api-service" = {
      image_tag_mutability = "IMMUTABLE"
      scan_on_push        = true
      force_delete        = false
      encryption_type     = "AES256"
      kms_key            = null
      repository_policy  = null
      lifecycle_policy   = null
      repository_type    = "private"
      tags = {
        Application = "api-service"
        Tier        = "backend"
      }
    }
    
    "my-worker" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push        = true
      force_delete        = true  # Allow deletion for worker images
      encryption_type     = "AES256"
      kms_key            = null
      repository_policy  = null
      # Custom lifecycle policy for worker images
      lifecycle_policy = jsonencode({
        rules = [
          {
            rulePriority = 1
            description  = "Keep last 10 worker images"
            selection = {
              tagStatus   = "tagged"
              countType   = "imageCountMoreThan"
              countNumber = 10
            }
            action = {
              type = "expire"
            }
          },
          {
            rulePriority = 2
            description  = "Expire untagged images after 1 day"
            selection = {
              tagStatus   = "untagged"
              countType   = "sinceImagePushed"
              countUnit   = "days"
              countNumber = 1
            }
            action = {
              type = "expire"
            }
          }
        ]
      })
      repository_type = "private"
      tags = {
        Application = "worker"
        Tier        = "background"
      }
    }
    
    "development-sandbox" = {
      image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"
      scan_on_push        = false  # Disabled for development
      force_delete        = true
      encryption_type     = "AES256"
      kms_key            = null
      repository_policy  = null
      lifecycle_policy   = null
      repository_type    = "private"
      # Allow mutable tags for development branches
      image_tag_mutability_exclusion_filters = [
        {
          filter      = "dev-*"
          filter_type = "WILDCARD"
        },
        {
          filter      = "feature-*"
          filter_type = "WILDCARD"
        },
        {
          filter      = "latest"
          filter_type = "WILDCARD"
        }
      ]
      tags = {
        Application = "sandbox"
        Environment = "development"
      }
    }
  }
}

variable "default_image_tag_mutability" {
  description = "Default image tag mutability for repositories"
  type        = string
  default     = "MUTABLE"
}

variable "default_force_delete" {
  description = "Default force delete setting for repositories"
  type        = bool
  default     = false
}

variable "default_scan_on_push" {
  description = "Default scan on push setting for repositories"
  type        = bool
  default     = true
}

variable "default_encryption_type" {
  description = "Default encryption type for repositories"
  type        = string
  default     = "AES256"
}

variable "default_kms_key" {
  description = "Default KMS key ARN for repository encryption"
  type        = string
  default     = null
}

variable "enable_default_lifecycle_policy" {
  description = "Whether to enable default lifecycle policy for repositories without custom policy"
  type        = bool
  default     = true
}

variable "default_lifecycle_policy_max_image_count" {
  description = "Maximum number of images to retain for tagged images in default lifecycle policy"
  type        = number
  default     = 30
}

variable "default_lifecycle_policy_untagged_days" {
  description = "Number of days after which to expire untagged images in default lifecycle policy"
  type        = number
  default     = 7
}

variable "enable_registry_scanning" {
  description = "Whether to enable registry-level scanning configuration"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Registry scan type for enhanced scanning"
  type        = string
  default     = "BASIC"
}

variable "registry_scanning_rules" {
  description = "List of registry scanning rules"
  type        = list(object({
    scan_frequency    = string
    repository_filter = string
    filter_type      = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "example"
    Project     = "terraform-ecr-module"
    Owner       = "platform-team"
  }
}

# Outputs
output "repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "repository_arns" {
  description = "ECR repository ARNs"
  value       = module.ecr.repository_arns
}

output "registry_id" {
  description = "Registry ID (AWS Account ID)"
  value       = module.ecr.registry_id
}

output "ecr_repositories_info" {
  description = "Complete ECR repositories information for CI/CD"
  value       = module.ecr.ecr_repositories_info
  sensitive   = false
}

output "repository_login_commands" {
  description = "Docker login commands for each repository"
  value       = module.ecr.repository_login_commands
}

output "lifecycle_policies" {
  description = "Applied lifecycle policies"
  value       = module.ecr.lifecycle_policies
}

# Example usage outputs
output "example_docker_commands" {
  description = "Example Docker commands for using the repositories"
  value = {
    for repo_name, repo_info in module.ecr.ecr_repositories_info : repo_name => {
      login = repo_info.login_command
      build = "docker build -t ${repo_name}:latest ."
      tag   = "docker tag ${repo_name}:latest ${repo_info.repository_url}:latest"
      push  = "docker push ${repo_info.repository_url}:latest"
    }
  }
}