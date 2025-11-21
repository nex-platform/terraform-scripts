# ECR Module

This module manages Amazon ECR (Elastic Container Registry) repositories with comprehensive configuration options including lifecycle policies, image scanning, encryption, and replication.

## Features

- 🗃️ **ECR Repositories**: Create and manage multiple ECR repositories
- 🔄 **Lifecycle Policies**: Automatic image cleanup and retention policies
- 🔍 **Image Scanning**: Vulnerability scanning on push
- 🔐 **Encryption**: AES256 or KMS encryption support
- 🌍 **Replication**: Cross-region repository replication
- 🏷️ **Image Tag Mutability**: Configurable tag mutability settings
- 📋 **Repository Policies**: Fine-grained access control
- 🚀 **CI/CD Integration**: Ready-to-use commands for Docker operations

## Usage

### Basic Example

```hcl
module "ecr" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/ecr?ref=v1.0.0"

  repositories = {
    "my-app" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push        = true
      force_delete        = false
      encryption_type     = "AES256"
      tags = {
        Application = "my-app"
      }
    }
    
    "my-api" = {
      image_tag_mutability = "IMMUTABLE"
      scan_on_push        = true
      force_delete        = false
      encryption_type     = "AES256"
      tags = {
        Application = "my-api"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Example with Custom Policies

```hcl
module "ecr" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/ecr?ref=v1.0.0"

  repositories = {
    "production-app" = {
      image_tag_mutability = "IMMUTABLE"
      scan_on_push        = true
      force_delete        = false
      encryption_type     = "KMS"
      kms_key            = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
      
      # Custom lifecycle policy
      lifecycle_policy = jsonencode({
        rules = [
          {
            rulePriority = 1
            description  = "Keep last 50 production images"
            selection = {
              tagStatus     = "tagged"
              tagPrefixList = ["v", "release"]
              countType     = "imageCountMoreThan"
              countNumber   = 50
            }
            action = {
              type = "expire"
            }
          },
          {
            rulePriority = 2
            description  = "Expire untagged images after 3 days"
            selection = {
              tagStatus   = "untagged"
              countType   = "sinceImagePushed"
              countUnit   = "days"
              countNumber = 3
            }
            action = {
              type = "expire"
            }
          }
        ]
      })
      
      # Custom repository policy
      repository_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "AllowPull"
            Effect = "Allow"
            Principal = {
              AWS = [
                "arn:aws:iam::123456789012:role/EKSNodeInstanceRole",
                "arn:aws:iam::123456789012:role/CodeBuildServiceRole"
              ]
            }
            Action = [
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "ecr:BatchCheckLayerAvailability"
            ]
          }
        ]
      })
      
      tags = {
        Environment = "production"
        Critical    = "true"
      }
    }
    
    "development-app" = {
      image_tag_mutability = "MUTABLE"
      scan_on_push        = true
      force_delete        = true  # Allow deletion in development
      encryption_type     = "AES256"
      
      tags = {
        Environment = "development"
      }
    }
  }

  # Registry-level configuration
  enable_registry_scanning = true
  registry_scan_type      = "ENHANCED"
  
  registry_scanning_rules = [
    {
      scan_frequency    = "SCAN_ON_PUSH"
      repository_filter = "*"
      filter_type      = "WILDCARD"
    }
  ]

  # Cross-region replication
  enable_replication = true
  replication_rules = [
    {
      destinations = [
        {
          region      = "us-east-1"
          registry_id = "123456789012"
        }
      ]
      repository_filters = [
        {
          filter      = "production-*"
          filter_type = "PREFIX_MATCH"
        }
      ]
    }
  ]

  # Pull-through cache for public registries
  pull_through_cache_rules = {
    "docker-hub" = {
      upstream_registry_url = "registry-1.docker.io"
      credential_arn       = null
    }
    "ghcr" = {
      upstream_registry_url = "ghcr.io"
      credential_arn       = null
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

### Example with Image Tag Mutability Exclusions

```hcl
module "ecr" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/ecr?ref=v1.0.0"

  repositories = {
    "flexible-app" = {
      image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"
      scan_on_push        = true
      force_delete        = false
      encryption_type     = "AES256"
      
      # Allow mutable tags for development
      image_tag_mutability_exclusion_filters = [
        {
          filter      = "dev-*"
          filter_type = "WILDCARD"
        },
        {
          filter      = "latest"
          filter_type = "WILDCARD"
        }
      ]
      
      tags = {
        Application = "flexible-app"
      }
    }
  }

  tags = {
    Environment = "mixed"
    Project     = "my-project"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.12.1 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repositories | Map of ECR repository configurations | `map(object({...}))` | `{}` | no |
| default_image_tag_mutability | Default image tag mutability for repositories | `string` | `"MUTABLE"` | no |
| default_force_delete | Default force delete setting for repositories | `bool` | `false` | no |
| default_scan_on_push | Default scan on push setting for repositories | `bool` | `true` | no |
| default_encryption_type | Default encryption type for repositories | `string` | `"AES256"` | no |
| default_kms_key | Default KMS key ARN for repository encryption | `string` | `null` | no |
| enable_default_lifecycle_policy | Whether to enable default lifecycle policy | `bool` | `true` | no |
| default_lifecycle_policy_max_image_count | Maximum number of images to retain for tagged images | `number` | `30` | no |
| default_lifecycle_policy_untagged_days | Days after which to expire untagged images | `number` | `7` | no |
| enable_registry_scanning | Whether to enable registry-level scanning | `bool` | `false` | no |
| registry_scan_type | Registry scan type for enhanced scanning | `string` | `"BASIC"` | no |
| registry_scanning_rules | List of registry scanning rules | `list(object({...}))` | `[]` | no |
| enable_replication | Whether to enable ECR replication | `bool` | `false` | no |
| replication_rules | List of replication rules | `list(object({...}))` | `[]` | no |
| pull_through_cache_rules | Map of pull through cache rules | `map(object({...}))` | `{}` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_arns | Map of repository ARNs |
| repository_urls | Map of repository URLs |
| repository_registry_ids | Map of repository registry IDs |
| repositories | Map of repository attributes |
| public_repository_arns | Map of public repository ARNs |
| public_repository_urls | Map of public repository URLs |
| public_repositories | Map of public repository attributes |
| registry_scanning_configuration | Registry scanning configuration |
| replication_configuration | Registry replication configuration |
| pull_through_cache_rules | Map of pull through cache rules |
| lifecycle_policies | Map of lifecycle policies applied to repositories |
| repository_policies | Map of repository policies |
| repository_login_commands | Docker login commands for each repository |
| repository_push_commands | Docker push commands for each repository |
| registry_id | Registry ID (AWS Account ID) |
| ecr_repositories_info | Combined information for CI/CD integration |

## Repository Configuration

The `repositories` variable accepts a map where each key is the repository name and the value is an object with the following structure:

```hcl
repositories = {
  "repository-name" = {
    # Image Configuration
    image_tag_mutability = string  # MUTABLE, IMMUTABLE, IMMUTABLE_WITH_EXCLUSION, MUTABLE_WITH_EXCLUSION
    force_delete         = bool    # Whether to delete repository even if it contains images
    scan_on_push        = bool    # Enable vulnerability scanning on image push
    
    # Encryption
    encryption_type = string      # AES256 or KMS
    kms_key        = string      # KMS key ARN (required if encryption_type is KMS)
    
    # Policies
    repository_policy = string    # JSON policy document for repository access
    lifecycle_policy  = string    # JSON policy document for image lifecycle
    
    # Public Repository Configuration (if repository_type is "public")
    repository_type   = string         # "private" or "public"
    about_text       = string         # Repository description
    architectures    = list(string)   # Supported architectures
    description      = string         # Short description
    operating_systems = list(string)  # Supported OS
    usage_text       = string         # Usage instructions
    
    # Image Tag Mutability Exclusions
    image_tag_mutability_exclusion_filters = list(object({
      filter      = string  # Filter pattern
      filter_type = string  # WILDCARD
    }))
    
    # Tags
    tags = map(string)
  }
}
```

## Lifecycle Policy Examples

### Keep Last N Tagged Images
```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 20 images",
      "selection": {
        "tagStatus": "tagged",
        "countType": "imageCountMoreThan",
        "countNumber": 20
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

### Expire Old Untagged Images
```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged images older than 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

### Keep Production Images, Expire Development
```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep production images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v", "release", "prod"],
        "countType": "imageCountMoreThan",
        "countNumber": 100
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep only 5 development images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["dev", "feature"],
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

## CI/CD Integration

The module provides useful outputs for CI/CD integration:

```yaml
# GitHub Actions example
- name: Login to Amazon ECR
  run: |
    ${{ steps.terraform.outputs.repository_login_commands.my-app }}

- name: Build and push Docker image
  run: |
    docker build -t my-app:${{ github.sha }} .
    ${{ steps.terraform.outputs.repository_push_commands.my-app.tag_command }}
    ${{ steps.terraform.outputs.repository_push_commands.my-app.push_command }}
```

## Security Considerations

- **Encryption**: Use KMS encryption for sensitive applications
- **Image Scanning**: Enable scan_on_push for vulnerability detection
- **Repository Policies**: Implement least-privilege access controls
- **Lifecycle Policies**: Regularly clean up old images to reduce costs
- **Private Repositories**: Keep repositories private unless public access is required

## Examples

Complete examples are available in the [examples/basic](./examples/basic/) directory.

## Contributing

When contributing to this module:

1. Test different repository configurations
2. Validate lifecycle and repository policies
3. Update documentation for new features
4. Follow AWS ECR best practices
5. Test with both private and public repositories

## License

This module is licensed under the MIT License.