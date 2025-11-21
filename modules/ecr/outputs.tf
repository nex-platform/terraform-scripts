# Repository Outputs
output "repository_arns" {
  description = "Map of repository ARNs"
  value = {
    for k, v in aws_ecr_repository.repository : k => v.arn
  }
}

output "repository_urls" {
  description = "Map of repository URLs"
  value = {
    for k, v in aws_ecr_repository.repository : k => v.repository_url
  }
}

output "repository_registry_ids" {
  description = "Map of repository registry IDs"
  value = {
    for k, v in aws_ecr_repository.repository : k => v.registry_id
  }
}

output "repositories" {
  description = "Map of repository attributes"
  value = {
    for k, v in aws_ecr_repository.repository : k => {
      arn                  = v.arn
      name                = v.name
      registry_id         = v.registry_id
      repository_url      = v.repository_url
      image_tag_mutability = v.image_tag_mutability
      tags                = v.tags
      tags_all            = v.tags_all
    }
  }
}

# Public Repository Outputs
output "public_repository_arns" {
  description = "Map of public repository ARNs"
  value = {
    for k, v in aws_ecrpublic_repository.public_repository : k => v.arn
  }
}

output "public_repository_urls" {
  description = "Map of public repository URLs"
  value = {
    for k, v in aws_ecrpublic_repository.public_repository : k => v.repository_uri
  }
}

output "public_repositories" {
  description = "Map of public repository attributes"
  value = {
    for k, v in aws_ecrpublic_repository.public_repository : k => {
      arn           = v.arn
      registry_id   = v.registry_id
      repository_uri = v.repository_uri
      tags          = v.tags
      tags_all      = v.tags_all
    }
  }
}

# Registry Configuration Outputs
output "registry_scanning_configuration" {
  description = "Registry scanning configuration"
  value = var.enable_registry_scanning ? {
    scan_type = aws_ecr_registry_scanning_configuration.scanning[0].scan_type
    rules     = aws_ecr_registry_scanning_configuration.scanning[0].rule
  } : null
}

output "replication_configuration" {
  description = "Registry replication configuration"
  value = var.enable_replication ? {
    rules = aws_ecr_replication_configuration.replication[0].replication_configuration[0].rule
  } : null
}

# Pull Through Cache Rules Outputs
output "pull_through_cache_rules" {
  description = "Map of pull through cache rules"
  value = {
    for k, v in aws_ecr_pull_through_cache_rule.cache_rules : k => {
      ecr_repository_prefix = v.ecr_repository_prefix
      registry_id          = v.registry_id
      upstream_registry_url = v.upstream_registry_url
      credential_arn       = v.credential_arn
    }
  }
}

# Lifecycle Policy Outputs
output "lifecycle_policies" {
  description = "Map of lifecycle policies applied to repositories"
  value = {
    for k, v in aws_ecr_lifecycle_policy.policy : k => {
      repository  = v.repository
      registry_id = v.registry_id
      policy      = v.policy
    }
  }
}

# Repository Policy Outputs
output "repository_policies" {
  description = "Map of repository policies"
  value = {
    for k, v in aws_ecr_repository_policy.policy : k => {
      repository  = v.repository
      registry_id = v.registry_id
      policy      = v.policy
    }
  }
}

# Useful outputs for CI/CD integration
output "repository_login_commands" {
  description = "Docker login commands for each repository"
  value = {
    for k, v in aws_ecr_repository.repository : k => 
    "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${v.repository_url}"
  }
}

output "repository_push_commands" {
  description = "Docker push commands for each repository"
  value = {
    for k, v in aws_ecr_repository.repository : k => {
      tag_command  = "docker tag ${k}:latest ${v.repository_url}:latest"
      push_command = "docker push ${v.repository_url}:latest"
    }
  }
}

# Data source for current region
data "aws_region" "current" {}

# Registry ID output (useful for cross-account access)
output "registry_id" {
  description = "Registry ID (AWS Account ID)"
  value       = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

# Combined output for easy consumption in CI/CD
output "ecr_repositories_info" {
  description = "Combined information about ECR repositories for CI/CD integration"
  value = {
    for k, v in aws_ecr_repository.repository : k => {
      name           = v.name
      arn            = v.arn
      registry_id    = v.registry_id
      repository_url = v.repository_url
      region         = data.aws_region.current.name
      login_command  = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${v.repository_url}"
      docker_tag     = "docker tag ${k}:$${IMAGE_TAG:-latest} ${v.repository_url}:$${IMAGE_TAG:-latest}"
      docker_push    = "docker push ${v.repository_url}:$${IMAGE_TAG:-latest}"
    }
  }
}