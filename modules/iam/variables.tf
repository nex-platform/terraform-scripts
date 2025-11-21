# IAM Roles Configuration
variable "roles" {
  description = "Map of IAM role configurations"
  type = map(object({
    assume_role_policy    = string
    description          = string
    force_detach_policies = bool
    max_session_duration = number
    path                 = string
    permissions_boundary = string
    attached_policies    = list(string)
    inline_policies      = map(string)
    tags                = map(string)
  }))
  default = {}
}

# IAM Policies Configuration
variable "policies" {
  description = "Map of IAM policy configurations"
  type = map(object({
    policy_document = string
    description    = string
    path          = string
    tags          = map(string)
  }))
  default = {}
}

# IAM Groups Configuration
variable "groups" {
  description = "Map of IAM group configurations"
  type = map(object({
    path              = string
    attached_policies = list(string)
    members          = list(string)
  }))
  default = {}
}

# IAM Users Configuration
variable "users" {
  description = "Map of IAM user configurations"
  type = map(object({
    path                 = string
    permissions_boundary = string
    force_destroy        = bool
    create_access_key    = bool
    attached_policies    = list(string)
    tags                = map(string)
  }))
  default = {}
}

# IAM Instance Profiles Configuration
variable "instance_profiles" {
  description = "Map of IAM instance profile configurations"
  type = map(object({
    role = string
    path = string
    tags = map(string)
  }))
  default = {}
}

# OIDC Identity Providers Configuration
variable "oidc_providers" {
  description = "Map of OIDC identity provider configurations"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
    tags           = map(string)
  }))
  default = {}
}

# SAML Identity Providers Configuration
variable "saml_providers" {
  description = "Map of SAML identity provider configurations"
  type = map(object({
    saml_metadata_document = string
    tags                  = map(string)
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}