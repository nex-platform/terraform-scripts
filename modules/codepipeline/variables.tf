# Required Variables
variable "pipeline_name" {
  description = "Name of the CodePipeline"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo-name'"
  type        = string
}

# Optional Variables - Pipeline Configuration
variable "pipeline_type" {
  description = "Type of the pipeline (V1 or V2)"
  type        = string
  default     = "V2"
  validation {
    condition     = contains(["V1", "V2"], var.pipeline_type)
    error_message = "Pipeline type must be either V1 or V2."
  }
}

variable "github_branch" {
  description = "GitHub branch to use for the source stage"
  type        = string
  default     = "main"
}

# CodeStar Connection Configuration
variable "create_codestar_connection" {
  description = "Whether to create a new CodeStar connection"
  type        = bool
  default     = true
}

variable "codestar_connection_name" {
  description = "Name for the CodeStar connection (if creating new one)"
  type        = string
  default     = null
}

variable "existing_codestar_connection_arn" {
  description = "ARN of existing CodeStar connection (if not creating new one)"
  type        = string
  default     = null
}

# S3 Artifact Store Configuration
variable "create_artifact_bucket" {
  description = "Whether to create a new S3 bucket for artifacts"
  type        = bool
  default     = true
}

variable "artifact_bucket_name" {
  description = "Name for the artifact bucket (if creating new one)"
  type        = string
  default     = null
}

variable "existing_artifact_bucket_name" {
  description = "Name of existing S3 bucket for artifacts"
  type        = string
  default     = null
}

variable "existing_artifact_bucket_arn" {
  description = "ARN of existing S3 bucket for artifacts"
  type        = string
  default     = null
}

variable "artifact_bucket_kms_key_id" {
  description = "KMS key ID for encrypting artifacts in S3"
  type        = string
  default     = null
}

# IAM Role Configuration
variable "codepipeline_service_role_arn" {
  description = "ARN of existing IAM role for CodePipeline (if not creating new one)"
  type        = string
  default     = null
}

variable "codebuild_service_role_arn" {
  description = "ARN of existing IAM role for CodeBuild (if not creating new one)"
  type        = string
  default     = null
}

# Source Action Configuration
variable "source_action_configuration" {
  description = "Additional configuration for the source action"
  type        = map(string)
  default = {
    OutputArtifactFormat = "CODE_ZIP"
    DetectChanges       = "true"
  }
}

# CodeBuild Projects Configuration
variable "codebuild_projects" {
  description = "Map of CodeBuild project configurations"
  type = map(object({
    description                    = string
    compute_type                  = string
    image                        = string
    type                         = string
    privileged_mode              = bool
    image_pull_credentials_type  = string
    buildspec                    = string
    environment_variables        = map(string)
    parameter_store_variables    = map(string)
    secrets_manager_variables    = map(string)
    vpc_config = object({
      vpc_id             = string
      subnets           = list(string)
      security_group_ids = list(string)
    })
    tags = map(string)
  }))
  default = {}
}

# Build Stages Configuration
variable "build_stages" {
  description = "List of build stages to add to the pipeline"
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = string
      input_artifacts  = list(string)
      output_artifacts = list(string)
      configuration    = map(string)
      run_order        = number
      region           = string
      role_arn         = string
    }))
  }))
  default = []
}

# Deploy Stages Configuration
variable "deploy_stages" {
  description = "List of deploy stages to add to the pipeline"
  type = list(object({
    name = string
    actions = list(object({
      name             = string
      category         = string
      owner            = string
      provider         = string
      version          = string
      input_artifacts  = list(string)
      output_artifacts = list(string)
      configuration    = map(string)
      run_order        = number
      region           = string
      role_arn         = string
    }))
  }))
  default = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}