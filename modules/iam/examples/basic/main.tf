# Basic IAM Resources Example
# This example creates common IAM roles and policies for application infrastructure

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

# Get current AWS account information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Module
module "iam" {
  source = "../../"

  # Custom Policies
  policies = var.policies

  # IAM Roles
  roles = var.roles

  # IAM Groups
  groups = var.groups

  # IAM Users
  users = var.users

  # Instance Profiles
  instance_profiles = var.instance_profiles

  # OIDC Providers
  oidc_providers = var.oidc_providers

  tags = var.tags
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "policies" {
  description = "Map of IAM policy configurations"
  type        = any
  default = {
    "s3-read-only-policy" = {
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:ListBucket"
            ]
            Resource = [
              "arn:aws:s3:::example-bucket",
              "arn:aws:s3:::example-bucket/*"
            ]
          }
        ]
      })
      description = "S3 read-only access policy"
      path        = "/"
      tags = {
        Purpose = "S3Access"
      }
    }
  }
}

variable "roles" {
  description = "Map of IAM role configurations"
  type        = any
  default = {
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
      force_detach_policies = false
      max_session_duration = 3600
      path                 = "/"
      permissions_boundary = null
      attached_policies = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
      inline_policies = {}
      tags = {
        Service = "EKS"
        Type    = "ServiceRole"
      }
    }
    
    "eks-node-role" = {
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
      description          = "EKS node group service role"
      force_detach_policies = false
      max_session_duration = 3600
      path                 = "/"
      permissions_boundary = null
      attached_policies = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
      inline_policies = {}
      tags = {
        Service = "EKS"
        Type    = "ServiceRole"
      }
    }
    
    "codepipeline-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "codepipeline.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      description          = "CodePipeline service role"
      force_detach_policies = false
      max_session_duration = 3600
      path                 = "/"
      permissions_boundary = null
      attached_policies    = []
      inline_policies = {
        "codepipeline-policy" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "s3:GetBucketVersioning",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject",
                "s3:PutObjectAcl"
              ]
              Resource = [
                "arn:aws:s3:::codepipeline-artifacts-*",
                "arn:aws:s3:::codepipeline-artifacts-*/*"
              ]
            },
            {
              Effect = "Allow"
              Action = [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
              ]
              Resource = "*"
            }
          ]
        })
      }
      tags = {
        Service = "CodePipeline"
        Type    = "ServiceRole"
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
      description          = "EC2 instance role with SSM access"
      force_detach_policies = false
      max_session_duration = 3600
      path                 = "/"
      permissions_boundary = null
      attached_policies = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      inline_policies = {}
      tags = {
        Service = "EC2"
        Type    = "ServiceRole"
      }
    }
  }
}

variable "groups" {
  description = "Map of IAM group configurations"
  type        = any
  default = {
    "developers" = {
      path = "/"
      attached_policies = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
      members = []
    }
  }
}

variable "users" {
  description = "Map of IAM user configurations"
  type        = any
  default = {}
}

variable "instance_profiles" {
  description = "Map of IAM instance profile configurations"
  type        = any
  default = {
    "ec2-instance-profile" = {
      role = "ec2-instance-role"
      path = "/"
      tags = {
        Service = "EC2"
      }
    }
  }
}

variable "oidc_providers" {
  description = "Map of OIDC identity provider configurations"
  type        = any
  default = {
    "github-actions" = {
      url = "https://token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
      thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
      tags = {
        Purpose = "GitHubActions"
        Service = "CI/CD"
      }
    }
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "example"
    Project     = "terraform-iam-module"
    Owner       = "platform-team"
  }
}

# Outputs
output "role_arns" {
  description = "Map of IAM role ARNs"
  value       = module.iam.role_arns
}

output "role_names" {
  description = "Map of IAM role names"
  value       = module.iam.role_names
}

output "policy_arns" {
  description = "Map of IAM policy ARNs"
  value       = module.iam.policy_arns
}

output "instance_profile_arns" {
  description = "Map of IAM instance profile ARNs"
  value       = module.iam.instance_profile_arns
}

output "oidc_provider_arns" {
  description = "Map of OIDC identity provider ARNs"
  value       = module.iam.oidc_provider_arns
}

output "group_arns" {
  description = "Map of IAM group ARNs"
  value       = module.iam.group_arns
}

# Summary output for easy consumption
output "iam_summary" {
  description = "Summary of IAM resources created"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    roles_created = length(module.iam.role_arns)
    policies_created = length(module.iam.policy_arns)
    instance_profiles_created = length(module.iam.instance_profile_arns)
    oidc_providers_created = length(module.iam.oidc_provider_arns)
    groups_created = length(module.iam.group_arns)
  }
}