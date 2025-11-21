# CodePipeline Outputs
output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.pipeline.arn
}

output "pipeline_id" {
  description = "ID of the CodePipeline"
  value       = aws_codepipeline.pipeline.id
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "pipeline_url" {
  description = "URL to the CodePipeline in AWS Console"
  value       = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.pipeline.name}/view"
}

# CodeStar Connection Outputs
output "codestar_connection_arn" {
  description = "ARN of the CodeStar connection"
  value       = var.create_codestar_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_codestar_connection_arn
}

output "codestar_connection_status" {
  description = "Status of the CodeStar connection"
  value       = var.create_codestar_connection ? aws_codestarconnections_connection.github[0].connection_status : null
}

output "codestar_connection_setup_url" {
  description = "URL to complete CodeStar connection setup (if PENDING)"
  value       = var.create_codestar_connection ? "https://console.aws.amazon.com/codesuite/settings/connections" : null
}

# S3 Artifact Store Outputs
output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].bucket : var.existing_artifact_bucket_name
}

output "artifact_bucket_arn" {
  description = "ARN of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].arn : var.existing_artifact_bucket_arn
}

output "artifact_bucket_domain_name" {
  description = "Domain name of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].bucket_domain_name : null
}

output "artifact_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 artifact bucket"
  value       = var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].bucket_regional_domain_name : null
}

# CodeBuild Projects Outputs
output "codebuild_projects" {
  description = "Map of CodeBuild project attributes"
  value = {
    for k, v in aws_codebuild_project.build : k => {
      name         = v.name
      arn          = v.arn
      service_role = v.service_role
      badge_url    = v.badge_url
    }
  }
}

output "codebuild_project_names" {
  description = "List of CodeBuild project names"
  value       = [for project in aws_codebuild_project.build : project.name]
}

output "codebuild_project_arns" {
  description = "List of CodeBuild project ARNs"
  value       = [for project in aws_codebuild_project.build : project.arn]
}

# IAM Role Outputs
output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = var.codepipeline_service_role_arn != null ? var.codepipeline_service_role_arn : aws_iam_role.codepipeline[0].arn
}

output "codepipeline_role_name" {
  description = "Name of the CodePipeline service role"
  value       = var.codepipeline_service_role_arn != null ? null : aws_iam_role.codepipeline[0].name
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = var.codebuild_service_role_arn != null ? var.codebuild_service_role_arn : (length(aws_iam_role.codebuild) > 0 ? aws_iam_role.codebuild[0].arn : null)
}

output "codebuild_role_name" {
  description = "Name of the CodeBuild service role"
  value       = var.codebuild_service_role_arn != null ? null : (length(aws_iam_role.codebuild) > 0 ? aws_iam_role.codebuild[0].name : null)
}

# Pipeline Configuration Outputs
output "pipeline_stages" {
  description = "List of pipeline stage names"
  value       = concat(["Source"], [for stage in var.build_stages : stage.name], [for stage in var.deploy_stages : stage.name])
}

output "github_repository" {
  description = "GitHub repository configured for the pipeline"
  value       = var.github_repository
}

output "github_branch" {
  description = "GitHub branch configured for the pipeline"
  value       = var.github_branch
}

# Useful URLs for monitoring and management
output "cloudwatch_logs_urls" {
  description = "CloudWatch Logs URLs for CodeBuild projects"
  value = {
    for k, v in aws_codebuild_project.build : k => 
    "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#logStream:group=/aws/codebuild/${v.name}"
  }
}

output "codebuild_project_urls" {
  description = "AWS Console URLs for CodeBuild projects"
  value = {
    for k, v in aws_codebuild_project.build : k => 
    "https://console.aws.amazon.com/codesuite/codebuild/projects/${v.name}/view/new"
  }
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Summary output for easy consumption
output "pipeline_summary" {
  description = "Summary of the CodePipeline configuration"
  value = {
    pipeline_name           = aws_codepipeline.pipeline.name
    pipeline_arn           = aws_codepipeline.pipeline.arn
    pipeline_type          = var.pipeline_type
    github_repository      = var.github_repository
    github_branch          = var.github_branch
    artifact_bucket        = var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].bucket : var.existing_artifact_bucket_name
    codestar_connection    = var.create_codestar_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_codestar_connection_arn
    codebuild_projects     = [for project in aws_codebuild_project.build : project.name]
    pipeline_url           = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.pipeline.name}/view"
    region                 = data.aws_region.current.name
    account_id            = data.aws_caller_identity.current.account_id
  }
}