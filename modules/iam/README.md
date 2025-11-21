# IAM Module

This module manages AWS Identity and Access Management (IAM) resources including roles, policies, users, groups, instance profiles, and identity providers for application infrastructure.

## Features

- 👥 **IAM Roles**: Service roles with trust policies and attached policies
- 📋 **IAM Policies**: Custom and managed policies
- 🏛️ **IAM Groups**: User groups with policy attachments and memberships
- 👤 **IAM Users**: Individual users with access keys and policy attachments
- 💻 **Instance Profiles**: EC2 instance profiles for service roles
- 🔗 **Identity Providers**: OIDC and SAML identity providers
- 🔐 **Security**: Least-privilege access patterns and permissions boundaries

## Usage

### Basic Example

```hcl
module "iam" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/iam?ref=v1.0.0"

  # IAM Roles
  roles = {
    "eks-cluster-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "eks.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      description          = "EKS cluster service role"
      attached_policies    = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
      inline_policies      = {}
      tags = {
        Service = "EKS"
      }
    }
    
    "ec2-instance-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      description       = "EC2 instance role"
      attached_policies = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
      inline_policies   = {}
      tags = {
        Service = "EC2"
      }
    }
  }

  # Instance Profiles
  instance_profiles = {
    "ec2-instance-profile" = {
      role = "ec2-instance-role"
      tags = {
        Service = "EC2"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Example

```hcl
module "iam" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/iam?ref=v1.0.0"

  # Custom Policies
  policies = {
    "s3-access-policy" = {
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = "arn:aws:s3:::my-bucket/*"
          },
          {
            Effect = "Allow"
            Action = [
              "s3:ListBucket"
            ]
            Resource = "arn:aws:s3:::my-bucket"
          }
        ]
      })
      description = "S3 bucket access policy"
      tags = {
        Purpose = "S3Access"
      }
    }
  }

  # IAM Roles with custom policies
  roles = {
    "application-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      description       = "Application service role"
      max_session_duration = 7200
      attached_policies = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      inline_policies = {
        "cloudwatch-logs" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ]
              Resource = "arn:aws:logs:*:*:*"
            }
          ]
        })
      }
      tags = {
        Service = "Application"
      }
    }
  }

  # IAM Groups
  groups = {
    "developers" = {
      path = "/"
      attached_policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
      members = ["developer1", "developer2"]
    }
    
    "admins" = {
      path = "/"
      attached_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      members = ["admin1"]
    }
  }

  # IAM Users
  users = {
    "developer1" = {
      path                 = "/"
      force_destroy        = false
      create_access_key    = true
      attached_policies    = []
      tags = {
        Team = "Development"
      }
    }
    
    "developer2" = {
      path                 = "/"
      force_destroy        = false
      create_access_key    = true
      attached_policies    = []
      tags = {
        Team = "Development"
      }
    }
    
    "admin1" = {
      path                 = "/"
      force_destroy        = false
      create_access_key    = false
      attached_policies    = []
      tags = {
        Role = "Administrator"
      }
    }
  }

  # OIDC Identity Provider (for GitHub Actions)
  oidc_providers = {
    "github-actions" = {
      url = "https://token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
      thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
      tags = {
        Purpose = "GitHubActions"
      }
    }
  }

  tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
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
| roles | Map of IAM role configurations | `map(object({...}))` | `{}` | no |
| policies | Map of IAM policy configurations | `map(object({...}))` | `{}` | no |
| groups | Map of IAM group configurations | `map(object({...}))` | `{}` | no |
| users | Map of IAM user configurations | `map(object({...}))` | `{}` | no |
| instance_profiles | Map of IAM instance profile configurations | `map(object({...}))` | `{}` | no |
| oidc_providers | Map of OIDC identity provider configurations | `map(object({...}))` | `{}` | no |
| saml_providers | Map of SAML identity provider configurations | `map(object({...}))` | `{}` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arns | Map of IAM role ARNs |
| role_names | Map of IAM role names |
| role_unique_ids | Map of IAM role unique IDs |
| roles | Map of IAM role attributes |
| policy_arns | Map of IAM policy ARNs |
| policy_ids | Map of IAM policy IDs |
| policies | Map of IAM policy attributes |
| group_arns | Map of IAM group ARNs |
| group_names | Map of IAM group names |
| groups | Map of IAM group attributes |
| user_arns | Map of IAM user ARNs |
| user_names | Map of IAM user names |
| user_unique_ids | Map of IAM user unique IDs |
| users | Map of IAM user attributes |
| access_keys | Map of IAM access key IDs |
| access_key_secrets | Map of IAM access key secrets (sensitive) |
| instance_profile_arns | Map of IAM instance profile ARNs |
| instance_profile_names | Map of IAM instance profile names |
| instance_profiles | Map of IAM instance profile attributes |
| oidc_provider_arns | Map of OIDC identity provider ARNs |
| oidc_providers | Map of OIDC identity provider attributes |
| saml_provider_arns | Map of SAML identity provider ARNs |
| saml_providers | Map of SAML identity provider attributes |

## Common IAM Patterns

### EKS Service Roles
```hcl
roles = {
  "eks-cluster-role" = {
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = { Service = "eks.amazonaws.com" }
          Action = "sts:AssumeRole"
        }
      ]
    })
    attached_policies = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
  }
  
  "eks-node-role" = {
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = { Service = "ec2.amazonaws.com" }
          Action = "sts:AssumeRole"
        }
      ]
    })
    attached_policies = [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ]
  }
}
```

### CodePipeline Service Roles
```hcl
roles = {
  "codepipeline-role" = {
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = { Service = "codepipeline.amazonaws.com" }
          Action = "sts:AssumeRole"
        }
      ]
    })
    inline_policies = {
      "pipeline-policy" = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetBucketVersioning",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:PutObject"
            ]
            Resource = ["arn:aws:s3:::pipeline-artifacts/*"]
          }
        ]
      })
    }
  }
}
```

### GitHub Actions OIDC
```hcl
oidc_providers = {
  "github-actions" = {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  }
}

roles = {
  "github-actions-role" = {
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Federated = "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            }
            StringLike = {
              "token.actions.githubusercontent.com:sub" = "repo:my-org/my-repo:*"
            }
          }
        }
      ]
    })
    attached_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  }
}
```

## Security Best Practices

1. **Least Privilege**: Grant minimal permissions required for the task
2. **Permissions Boundaries**: Use permissions boundaries to limit maximum permissions
3. **Temporary Credentials**: Prefer roles over users with long-term access keys
4. **Regular Rotation**: Rotate access keys regularly
5. **MFA**: Enable MFA for sensitive operations
6. **Audit**: Use CloudTrail to monitor IAM actions

## Examples

Complete examples are available in the [examples/basic](./examples/basic/) directory.

## Contributing

When contributing to this module:

1. Follow AWS IAM best practices
2. Test with different role types and policies
3. Validate permissions boundaries work correctly
4. Update documentation for new features
5. Ensure sensitive outputs are marked as sensitive

## License

This module is licensed under the MIT License.