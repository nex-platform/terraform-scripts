# ECR Repository
resource "aws_ecr_repository" "repository" {
  for_each = var.repositories

  name                 = each.key
  image_tag_mutability = lookup(each.value, "image_tag_mutability", var.default_image_tag_mutability)
  force_delete         = lookup(each.value, "force_delete", var.default_force_delete)

  # Image scanning configuration
  image_scanning_configuration {
    scan_on_push = lookup(each.value, "scan_on_push", var.default_scan_on_push)
  }

  # Encryption configuration
  dynamic "encryption_configuration" {
    for_each = lookup(each.value, "encryption_type", var.default_encryption_type) != null ? [1] : []
    content {
      encryption_type = lookup(each.value, "encryption_type", var.default_encryption_type)
      kms_key        = lookup(each.value, "kms_key", var.default_kms_key)
    }
  }

  # Image tag mutability exclusion filters
  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = lookup(each.value, "image_tag_mutability_exclusion_filters", [])
    content {
      filter      = image_tag_mutability_exclusion_filter.value.filter
      filter_type = image_tag_mutability_exclusion_filter.value.filter_type
    }
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# ECR Repository Policy
resource "aws_ecr_repository_policy" "policy" {
  for_each = { for k, v in var.repositories : k => v if lookup(v, "repository_policy", null) != null }

  repository = aws_ecr_repository.repository[each.key].name
  policy     = each.value.repository_policy
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "policy" {
  for_each = { for k, v in var.repositories : k => v if lookup(v, "lifecycle_policy", null) != null || var.enable_default_lifecycle_policy }

  repository = aws_ecr_repository.repository[each.key].name
  policy = lookup(each.value, "lifecycle_policy", null) != null ? each.value.lifecycle_policy : jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.default_lifecycle_policy_max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "main", "master", "develop"]
          countType     = "imageCountMoreThan"
          countNumber   = var.default_lifecycle_policy_max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images older than ${var.default_lifecycle_policy_untagged_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.default_lifecycle_policy_untagged_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Public Access Block (if repository is public)
resource "aws_ecrpublic_repository" "public_repository" {
  for_each = { for k, v in var.repositories : k => v if lookup(v, "repository_type", "private") == "public" }

  repository_name = each.key
  catalog_data {
    about_text        = lookup(each.value, "about_text", "")
    architectures     = lookup(each.value, "architectures", ["x86-64"])
    description       = lookup(each.value, "description", "")
    operating_systems = lookup(each.value, "operating_systems", ["Linux"])
    usage_text        = lookup(each.value, "usage_text", "")
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# ECR Registry Scanning Configuration (applied at registry level)
resource "aws_ecr_registry_scanning_configuration" "scanning" {
  count = var.enable_registry_scanning ? 1 : 0

  scan_type = var.registry_scan_type

  dynamic "rule" {
    for_each = var.registry_scanning_rules
    content {
      scan_frequency = rule.value.scan_frequency
      repository_filter {
        filter      = rule.value.repository_filter
        filter_type = rule.value.filter_type
      }
    }
  }
}

# ECR Replication Configuration
resource "aws_ecr_replication_configuration" "replication" {
  count = var.enable_replication ? 1 : 0

  dynamic "replication_configuration" {
    for_each = [1]
    content {
      dynamic "rule" {
        for_each = var.replication_rules
        content {
          dynamic "destination" {
            for_each = rule.value.destinations
            content {
              region      = destination.value.region
              registry_id = destination.value.registry_id
            }
          }
          dynamic "repository_filter" {
            for_each = lookup(rule.value, "repository_filters", [])
            content {
              filter      = repository_filter.value.filter
              filter_type = repository_filter.value.filter_type
            }
          }
        }
      }
    }
  }
}

# ECR Pull Through Cache Rules
resource "aws_ecr_pull_through_cache_rule" "cache_rules" {
  for_each = var.pull_through_cache_rules

  ecr_repository_prefix = each.key
  upstream_registry_url = each.value.upstream_registry_url
  credential_arn        = lookup(each.value, "credential_arn", null)
}