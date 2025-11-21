# CodePipeline Module

This module creates an AWS CodePipeline with GitHub App integration using CodeStar connections, supporting build and deploy stages with CodeBuild projects.

## Features

- 🔗 **GitHub App Integration**: Secure GitHub integration using CodeStar connections
- 🏗️ **CodeBuild Integration**: Automated build projects with customizable environments
- 📦 **S3 Artifact Store**: Secure artifact storage with encryption support
- 🔐 **IAM Roles**: Least-privilege IAM roles for pipeline and build operations
- ⚡ **Pipeline V2**: Support for latest CodePipeline features
- 🏷️ **Flexible Stages**: Configurable build and deploy stages
- 🔍 **Monitoring**: CloudWatch integration for logging and monitoring

## Usage

### Basic Example

```hcl
module "codepipeline" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/codepipeline?ref=v1.0.0"

  pipeline_name     = "my-app-pipeline"
  github_repository = "my-org/my-app"
  github_branch     = "main"

  # Basic CodeBuild project
  codebuild_projects = {
    "my-app-build" = {
      description   = "Build project for my-app"
      compute_type  = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      privileged_mode = true
      buildspec    = "buildspec.yml"
      environment_variables = {
        AWS_DEFAULT_REGION = "us-west-2"
        IMAGE_REPO_NAME   = "my-app"
      }
      tags = {
        Project = "my-app"
      }
    }
  }

  # Build stage
  build_stages = [
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
            ProjectName = "my-app-build"
          }
          run_order = null
          region    = null
          role_arn  = null
        }
      ]
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Advanced Example with Multiple Stages

```hcl
module "codepipeline" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/codepipeline?ref=v1.0.0"

  pipeline_name     = "microservice-pipeline"
  pipeline_type     = "V2"
  github_repository = "my-org/microservice"
  github_branch     = "main"

  # Custom artifact bucket
  create_artifact_bucket = true
  artifact_bucket_name   = "microservice-pipeline-artifacts"
  artifact_bucket_kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  # CodeBuild projects for different stages
  codebuild_projects = {
    "unit-tests" = {
      description   = "Run unit tests"
      compute_type  = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      privileged_mode = false
      buildspec    = "buildspec-test.yml"
      environment_variables = {
        NODE_ENV = "test"
      }
      parameter_store_variables = {
        DATABASE_URL = "/microservice/test/database-url"
      }
      tags = {
        Purpose = "testing"
      }
    }
    
    "build-and-push" = {
      description   = "Build Docker image and push to ECR"
      compute_type  = "BUILD_GENERAL1_MEDIUM"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      privileged_mode = true  # Required for Docker builds
      buildspec    = "buildspec-build.yml"
      environment_variables = {
        AWS_DEFAULT_REGION = "us-west-2"
        IMAGE_REPO_NAME   = "microservice"
        IMAGE_TAG         = "latest"
      }
      secrets_manager_variables = {
        DOCKER_HUB_TOKEN = "docker-hub-credentials:token"
      }
      tags = {
        Purpose = "build"
      }
    }
    
    "security-scan" = {
      description   = "Security and vulnerability scanning"
      compute_type  = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      privileged_mode = false
      buildspec    = "buildspec-security.yml"
      environment_variables = {
        SCAN_TYPE = "full"
      }
      tags = {
        Purpose = "security"
      }
    }
  }

  # Build stages with parallel and sequential execution
  build_stages = [
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
            ProjectName = "unit-tests"
          }
          run_order = 1
          region    = null
          role_arn  = null
        },
        {
          name             = "SecurityScan"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          version          = "1"
          input_artifacts  = ["source_output"]
          output_artifacts = ["security_output"]
          configuration = {
            ProjectName = "security-scan"
          }
          run_order = 1  # Parallel with UnitTests
          region    = null
          role_arn  = null
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name             = "BuildAndPush"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          version          = "1"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          configuration = {
            ProjectName = "build-and-push"
          }
          run_order = null
          region    = null
          role_arn  = null
        }
      ]
    }
  ]

  # Deploy stages
  deploy_stages = [
    {
      name = "DeployToStaging"
      actions = [
        {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "ECS"
          version          = "1"
          input_artifacts  = ["build_output"]
          output_artifacts = null
          configuration = {
            ClusterName   = "staging-cluster"
            ServiceName   = "microservice"
            FileName      = "imagedefinitions.json"
          }
          run_order = null
          region    = null
          role_arn  = null
        }
      ]
    }
  ]

  tags = {
    Environment = "production"
    Project     = "microservice"
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
| pipeline_name | Name of the CodePipeline | `string` | n/a | yes |
| github_repository | GitHub repository in format 'owner/repo-name' | `string` | n/a | yes |
| pipeline_type | Type of the pipeline (V1 or V2) | `string` | `"V2"` | no |
| github_branch | GitHub branch to use for the source stage | `string` | `"main"` | no |
| create_codestar_connection | Whether to create a new CodeStar connection | `bool` | `true` | no |
| codestar_connection_name | Name for the CodeStar connection | `string` | `null` | no |
| existing_codestar_connection_arn | ARN of existing CodeStar connection | `string` | `null` | no |
| create_artifact_bucket | Whether to create a new S3 bucket for artifacts | `bool` | `true` | no |
| artifact_bucket_name | Name for the artifact bucket | `string` | `null` | no |
| existing_artifact_bucket_name | Name of existing S3 bucket for artifacts | `string` | `null` | no |
| existing_artifact_bucket_arn | ARN of existing S3 bucket for artifacts | `string` | `null` | no |
| artifact_bucket_kms_key_id | KMS key ID for encrypting artifacts in S3 | `string` | `null` | no |
| codepipeline_service_role_arn | ARN of existing IAM role for CodePipeline | `string` | `null` | no |
| codebuild_service_role_arn | ARN of existing IAM role for CodeBuild | `string` | `null` | no |
| source_action_configuration | Additional configuration for the source action | `map(string)` | `{}` | no |
| codebuild_projects | Map of CodeBuild project configurations | `map(object({...}))` | `{}` | no |
| build_stages | List of build stages to add to the pipeline | `list(object({...}))` | `[]` | no |
| deploy_stages | List of deploy stages to add to the pipeline | `list(object({...}))` | `[]` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| pipeline_arn | ARN of the CodePipeline |
| pipeline_id | ID of the CodePipeline |
| pipeline_name | Name of the CodePipeline |
| pipeline_url | URL to the CodePipeline in AWS Console |
| codestar_connection_arn | ARN of the CodeStar connection |
| codestar_connection_status | Status of the CodeStar connection |
| codestar_connection_setup_url | URL to complete CodeStar connection setup |
| artifact_bucket_name | Name of the S3 artifact bucket |
| artifact_bucket_arn | ARN of the S3 artifact bucket |
| codebuild_projects | Map of CodeBuild project attributes |
| codebuild_project_names | List of CodeBuild project names |
| codebuild_project_arns | List of CodeBuild project ARNs |
| codepipeline_role_arn | ARN of the CodePipeline service role |
| codebuild_role_arn | ARN of the CodeBuild service role |
| pipeline_summary | Summary of the CodePipeline configuration |

## CodeStar Connection Setup

After creating the pipeline, you'll need to complete the GitHub App connection:

1. Go to the [AWS CodeSuite Connections](https://console.aws.amazon.com/codesuite/settings/connections) page
2. Find your connection (status will be "Pending")
3. Click "Update pending connection"
4. Follow the GitHub App installation process
5. Authorize the connection

The pipeline will not work until this connection is completed.

## CodeBuild Project Configuration

CodeBuild projects support various configurations:

### Environment Variables
- **PLAINTEXT**: Regular environment variables
- **PARAMETER_STORE**: Values from AWS Systems Manager Parameter Store
- **SECRETS_MANAGER**: Values from AWS Secrets Manager

### Compute Types
- **BUILD_GENERAL1_SMALL**: 3 GB memory, 2 vCPUs
- **BUILD_GENERAL1_MEDIUM**: 7 GB memory, 4 vCPUs
- **BUILD_GENERAL1_LARGE**: 15 GB memory, 8 vCPUs
- **BUILD_GENERAL1_2XLARGE**: 144 GB memory, 72 vCPUs

### Example Buildspec Files

#### Basic Build (buildspec.yml)
```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
```

#### Test Build (buildspec-test.yml)
```yaml
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
      - npm run coverage
  post_build:
    commands:
      - echo Test completed on `date`
artifacts:
  files:
    - coverage/**/*
  name: test-results
```

## Security Considerations

- **GitHub App**: More secure than personal access tokens
- **IAM Roles**: Least-privilege access for pipeline and build operations
- **Artifact Encryption**: KMS encryption for artifact storage
- **VPC Support**: CodeBuild can run in private subnets
- **Secrets Management**: Use Parameter Store or Secrets Manager for sensitive data

## Examples

Complete examples are available in the [examples/basic](./examples/basic/) directory.

## Contributing

When contributing to this module:

1. Test with different CodeBuild configurations
2. Validate IAM permissions are minimal
3. Test GitHub App integration setup
4. Update documentation for new features
5. Follow AWS CodePipeline best practices

## License

This module is licensed under the MIT License.