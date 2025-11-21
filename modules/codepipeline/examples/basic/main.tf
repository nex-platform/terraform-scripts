# Basic CodePipeline Example
# This example creates a CodePipeline with GitHub App integration

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

# CodePipeline Module
module "codepipeline" {
  source = "../../"

  pipeline_name     = var.pipeline_name
  pipeline_type     = var.pipeline_type
  github_repository = var.github_repository
  github_branch     = var.github_branch

  # CodeStar connection
  create_codestar_connection = var.create_codestar_connection
  codestar_connection_name   = var.codestar_connection_name

  # Artifact bucket
  create_artifact_bucket     = var.create_artifact_bucket
  artifact_bucket_name       = var.artifact_bucket_name
  artifact_bucket_kms_key_id = var.artifact_bucket_kms_key_id

  # Source configuration
  source_action_configuration = var.source_action_configuration

  # CodeBuild projects
  codebuild_projects = var.codebuild_projects

  # Build stages
  build_stages = var.build_stages

  # Deploy stages (optional)
  deploy_stages = var.deploy_stages

  tags = var.tags
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "pipeline_name" {
  description = "Name of the CodePipeline"
  type        = string
  default     = "example-pipeline"
}

variable "pipeline_type" {
  description = "Type of the pipeline (V1 or V2)"
  type        = string
  default     = "V2"
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo-name'"
  type        = string
  default     = "example-org/example-app"
}

variable "github_branch" {
  description = "GitHub branch to use for the source stage"
  type        = string
  default     = "main"
}

variable "create_codestar_connection" {
  description = "Whether to create a new CodeStar connection"
  type        = bool
  default     = true
}

variable "codestar_connection_name" {
  description = "Name for the CodeStar connection"
  type        = string
  default     = "example-github-connection"
}

variable "create_artifact_bucket" {
  description = "Whether to create a new S3 bucket for artifacts"
  type        = bool
  default     = true
}

variable "artifact_bucket_name" {
  description = "Name for the artifact bucket"
  type        = string
  default     = null
}

variable "artifact_bucket_kms_key_id" {
  description = "KMS key ID for encrypting artifacts in S3"
  type        = string
  default     = null
}

variable "source_action_configuration" {
  description = "Additional configuration for the source action"
  type        = map(string)
  default = {
    OutputArtifactFormat = "CODE_ZIP"
    DetectChanges       = "true"
  }
}

variable "codebuild_projects" {
  description = "Map of CodeBuild project configurations"
  type        = any
  default = {
    "build-project" = {
      description                   = "Build project for the example application"
      compute_type                 = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/standard:7.0"
      type                        = "LINUX_CONTAINER"
      privileged_mode             = true
      image_pull_credentials_type = "CODEBUILD"
      buildspec                   = "buildspec.yml"
      environment_variables = {
        AWS_DEFAULT_REGION = "us-west-2"
        IMAGE_REPO_NAME   = "example-app"
        IMAGE_TAG         = "latest"
      }
      parameter_store_variables   = {}
      secrets_manager_variables   = {}
      vpc_config                  = null
      tags = {
        Purpose = "build"
      }
    }
    
    "test-project" = {
      description                   = "Test project for running unit tests"
      compute_type                 = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/standard:7.0"
      type                        = "LINUX_CONTAINER"
      privileged_mode             = false
      image_pull_credentials_type = "CODEBUILD"
      buildspec                   = "buildspec-test.yml"
      environment_variables = {
        NODE_ENV = "test"
      }
      parameter_store_variables   = {}
      secrets_manager_variables   = {}
      vpc_config                  = null
      tags = {
        Purpose = "testing"
      }
    }
  }
}

variable "build_stages" {
  description = "List of build stages to add to the pipeline"
  type        = any
  default = [
    {
      name = "Test"
      actions = [
        {
          name             = "UnitTests"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          version          = "1"
          input_artifacts  = ["source_output"]
          output_artifacts = ["test_output"]
          configuration = {
            ProjectName = "test-project"
          }
          run_order = null
          region    = null
          role_arn  = null
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          version          = "1"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          configuration = {
            ProjectName = "build-project"
          }
          run_order = null
          region    = null
          role_arn  = null
        }
      ]
    }
  ]
}

variable "deploy_stages" {
  description = "List of deploy stages to add to the pipeline"
  type        = any
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "example"
    Project     = "terraform-codepipeline-module"
    Owner       = "platform-team"
  }
}

# Outputs
output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = module.codepipeline.pipeline_arn
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.codepipeline.pipeline_name
}

output "pipeline_url" {
  description = "URL to the CodePipeline in AWS Console"
  value       = module.codepipeline.pipeline_url
}

output "codestar_connection_arn" {
  description = "ARN of the CodeStar connection"
  value       = module.codepipeline.codestar_connection_arn
}

output "codestar_connection_status" {
  description = "Status of the CodeStar connection"
  value       = module.codepipeline.codestar_connection_status
}

output "codestar_connection_setup_url" {
  description = "URL to complete CodeStar connection setup"
  value       = module.codepipeline.codestar_connection_setup_url
}

output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = module.codepipeline.artifact_bucket_name
}

output "codebuild_projects" {
  description = "CodeBuild project details"
  value       = module.codepipeline.codebuild_projects
}

output "pipeline_summary" {
  description = "Summary of the CodePipeline configuration"
  value       = module.codepipeline.pipeline_summary
}

# Instructions output
output "setup_instructions" {
  description = "Instructions for completing the setup"
  value = <<-EOT
    
    🚀 CodePipeline Setup Complete!
    
    📋 Next Steps:
    1. Complete GitHub App connection at: ${module.codepipeline.codestar_connection_setup_url}
    2. View your pipeline at: ${module.codepipeline.pipeline_url}
    3. Create buildspec.yml and buildspec-test.yml files in your repository
    
    📁 Example buildspec.yml:
    version: 0.2
    phases:
      pre_build:
        commands:
          - echo Logging in to Amazon ECR...
          - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      build:
        commands:
          - echo Build started on `date`
          - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      post_build:
        commands:
          - echo Build completed on `date`
    
    📁 Example buildspec-test.yml:
    version: 0.2
    phases:
      install:
        runtime-versions:
          nodejs: 18
      pre_build:
        commands:
          - npm install
      build:
        commands:
          - npm test
    
  EOT
}