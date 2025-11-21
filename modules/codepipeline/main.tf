# S3 Bucket for CodePipeline Artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = var.artifact_bucket_name != null ? var.artifact_bucket_name : "${var.pipeline_name}-artifacts-${random_id.bucket_suffix[0].hex}"

  tags = merge(var.tags, {
    Name = var.artifact_bucket_name != null ? var.artifact_bucket_name : "${var.pipeline_name}-artifacts"
  })
}

resource "random_id" "bucket_suffix" {
  count       = var.create_artifact_bucket ? 1 : 0
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.codepipeline_artifacts[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.codepipeline_artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  count  = var.create_artifact_bucket ? 1 : 0
  bucket = aws_s3_bucket.codepipeline_artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.artifact_bucket_kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.artifact_bucket_kms_key_id
    }
    bucket_key_enabled = var.artifact_bucket_kms_key_id != null ? true : false
  }
}

# CodeStar Connection for GitHub App integration
resource "aws_codestarconnections_connection" "github" {
  count         = var.create_codestar_connection ? 1 : 0
  name          = var.codestar_connection_name != null ? var.codestar_connection_name : "${var.pipeline_name}-github-connection"
  provider_type = "GitHub"

  tags = var.tags
}

# CodeBuild Project
resource "aws_codebuild_project" "build" {
  for_each = var.codebuild_projects

  name          = each.key
  description   = lookup(each.value, "description", "CodeBuild project for ${var.pipeline_name}")
  service_role  = var.codebuild_service_role_arn != null ? var.codebuild_service_role_arn : aws_iam_role.codebuild[0].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = lookup(each.value, "compute_type", "BUILD_GENERAL1_SMALL")
    image                      = lookup(each.value, "image", "aws/codebuild/standard:7.0")
    type                       = lookup(each.value, "type", "LINUX_CONTAINER")
    privileged_mode            = lookup(each.value, "privileged_mode", false)
    image_pull_credentials_type = lookup(each.value, "image_pull_credentials_type", "CODEBUILD")

    dynamic "environment_variable" {
      for_each = lookup(each.value, "environment_variables", {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }

    dynamic "environment_variable" {
      for_each = lookup(each.value, "parameter_store_variables", {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PARAMETER_STORE"
      }
    }

    dynamic "environment_variable" {
      for_each = lookup(each.value, "secrets_manager_variables", {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "SECRETS_MANAGER"
      }
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = lookup(each.value, "buildspec", "buildspec.yml")
  }

  dynamic "vpc_config" {
    for_each = lookup(each.value, "vpc_config", null) != null ? [each.value.vpc_config] : []
    content {
      vpc_id = vpc_config.value.vpc_id
      subnets = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# CodePipeline IAM Role
resource "aws_iam_role" "codepipeline" {
  count = var.codepipeline_service_role_arn == null ? 1 : 0
  name  = "${var.pipeline_name}-codepipeline-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy" "codepipeline" {
  count = var.codepipeline_service_role_arn == null ? 1 : 0
  name  = "${var.pipeline_name}-codepipeline-policy"
  role  = aws_iam_role.codepipeline[0].id

  policy = jsonencode({
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
          var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].arn : var.existing_artifact_bucket_arn,
          var.create_artifact_bucket ? "${aws_s3_bucket.codepipeline_artifacts[0].arn}/*" : "${var.existing_artifact_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = [
          var.create_codestar_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_codestar_connection_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "arn:aws:codebuild:*:*:project/*"
      },
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

# CodeBuild IAM Role
resource "aws_iam_role" "codebuild" {
  count = var.codebuild_service_role_arn == null ? 1 : 0
  name  = "${var.pipeline_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "codebuild" {
  count = var.codebuild_service_role_arn == null ? 1 : 0
  name  = "${var.pipeline_name}-codebuild-policy"
  role  = aws_iam_role.codebuild[0].id

  policy = jsonencode({
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
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].arn : var.existing_artifact_bucket_arn,
          var.create_artifact_bucket ? "${aws_s3_bucket.codepipeline_artifacts[0].arn}/*" : "${var.existing_artifact_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodePipeline
resource "aws_codepipeline" "pipeline" {
  name         = var.pipeline_name
  pipeline_type = var.pipeline_type
  role_arn     = var.codepipeline_service_role_arn != null ? var.codepipeline_service_role_arn : aws_iam_role.codepipeline[0].arn

  artifact_store {
    location = var.create_artifact_bucket ? aws_s3_bucket.codepipeline_artifacts[0].bucket : var.existing_artifact_bucket_name
    type     = "S3"

    dynamic "encryption_key" {
      for_each = var.artifact_bucket_kms_key_id != null ? [1] : []
      content {
        id   = var.artifact_bucket_kms_key_id
        type = "KMS"
      }
    }
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn                = var.create_codestar_connection ? aws_codestarconnections_connection.github[0].arn : var.existing_codestar_connection_arn
        FullRepositoryId            = var.github_repository
        BranchName                  = var.github_branch
        OutputArtifactFormat        = lookup(var.source_action_configuration, "OutputArtifactFormat", "CODE_ZIP")
        DetectChanges               = lookup(var.source_action_configuration, "DetectChanges", true)
      }
    }
  }

  # Build Stages
  dynamic "stage" {
    for_each = var.build_stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = lookup(action.value, "input_artifacts", ["source_output"])
          output_artifacts = lookup(action.value, "output_artifacts", null)
          configuration    = lookup(action.value, "configuration", {})
          run_order        = lookup(action.value, "run_order", null)
          region           = lookup(action.value, "region", null)
          role_arn         = lookup(action.value, "role_arn", null)
        }
      }
    }
  }

  # Deploy Stages
  dynamic "stage" {
    for_each = var.deploy_stages
    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = lookup(action.value, "input_artifacts", ["source_output"])
          output_artifacts = lookup(action.value, "output_artifacts", null)
          configuration    = lookup(action.value, "configuration", {})
          run_order        = lookup(action.value, "run_order", null)
          region           = lookup(action.value, "region", null)
          role_arn         = lookup(action.value, "role_arn", null)
        }
      }
    }
  }

  tags = var.tags
}