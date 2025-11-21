# Required Variables
variable "repositories" {
  description = "Map of ECR repository configurations"
  type = map(object({
    image_tag_mutability = string
    force_delete         = bool
    scan_on_push        = bool
    encryption_type     = string
    kms_key            = string
    repository_policy  = string
    lifecycle_policy   = string
    repository_type    = string
    about_text         = string
    architectures      = list(string)
    description        = string
    operating_systems  = list(string)
    usage_text         = string
    tags              = map(string)
    image_tag_mutability_exclusion_filters = list(object({
      filter      = string
      filter_type = string
    }))
  }))
  default = {}
}

# Default Repository Configuration
variable "default_image_tag_mutability" {
  description = "Default image tag mutability for repositories"
  type        = string
  default     = "MUTABLE"
  validation {
    condition = contains([
      "MUTABLE", 
      "IMMUTABLE", 
      "IMMUTABLE_WITH_EXCLUSION", 
      "MUTABLE_WITH_EXCLUSION"
    ], var.default_image_tag_mutability)
    error_message = "Image tag mutability must be one of: MUTABLE, IMMUTABLE, IMMUTABLE_WITH_EXCLUSION, MUTABLE_WITH_EXCLUSION."
  }
}

variable "default_force_delete" {
  description = "Default force delete setting for repositories"
  type        = bool
  default     = false
}

variable "default_scan_on_push" {
  description = "Default scan on push setting for repositories"
  type        = bool
  default     = true
}

variable "default_encryption_type" {
  description = "Default encryption type for repositories"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.default_encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "default_kms_key" {
  description = "Default KMS key ARN for repository encryption when encryption_type is KMS"
  type        = string
  default     = null
}

# Lifecycle Policy Configuration
variable "enable_default_lifecycle_policy" {
  description = "Whether to enable default lifecycle policy for repositories without custom policy"
  type        = bool
  default     = true
}

variable "default_lifecycle_policy_max_image_count" {
  description = "Maximum number of images to retain for tagged images in default lifecycle policy"
  type        = number
  default     = 30
}

variable "default_lifecycle_policy_untagged_days" {
  description = "Number of days after which to expire untagged images in default lifecycle policy"
  type        = number
  default     = 7
}

# Registry Scanning Configuration
variable "enable_registry_scanning" {
  description = "Whether to enable registry-level scanning configuration"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Registry scan type for enhanced scanning"
  type        = string
  default     = "BASIC"
  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.registry_scan_type)
    error_message = "Registry scan type must be either BASIC or ENHANCED."
  }
}

variable "registry_scanning_rules" {
  description = "List of registry scanning rules"
  type = list(object({
    scan_frequency    = string
    repository_filter = string
    filter_type      = string
  }))
  default = []
}

# Replication Configuration
variable "enable_replication" {
  description = "Whether to enable ECR replication configuration"
  type        = bool
  default     = false
}

variable "replication_rules" {
  description = "List of replication rules"
  type = list(object({
    destinations = list(object({
      region      = string
      registry_id = string
    }))
    repository_filters = list(object({
      filter      = string
      filter_type = string
    }))
  }))
  default = []
}

# Pull Through Cache Rules
variable "pull_through_cache_rules" {
  description = "Map of pull through cache rules"
  type = map(object({
    upstream_registry_url = string
    credential_arn       = string
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}