# IAM Role Outputs
output "role_arns" {
  description = "Map of IAM role ARNs"
  value = {
    for k, v in aws_iam_role.roles : k => v.arn
  }
}

output "role_names" {
  description = "Map of IAM role names"
  value = {
    for k, v in aws_iam_role.roles : k => v.name
  }
}

output "role_unique_ids" {
  description = "Map of IAM role unique IDs"
  value = {
    for k, v in aws_iam_role.roles : k => v.unique_id
  }
}

output "roles" {
  description = "Map of IAM role attributes"
  value = {
    for k, v in aws_iam_role.roles : k => {
      arn                   = v.arn
      name                  = v.name
      unique_id            = v.unique_id
      create_date          = v.create_date
      description          = v.description
      max_session_duration = v.max_session_duration
      path                 = v.path
      permissions_boundary = v.permissions_boundary
      tags                 = v.tags
      tags_all            = v.tags_all
    }
  }
}

# IAM Policy Outputs
output "policy_arns" {
  description = "Map of IAM policy ARNs"
  value = {
    for k, v in aws_iam_policy.policies : k => v.arn
  }
}

output "policy_ids" {
  description = "Map of IAM policy IDs"
  value = {
    for k, v in aws_iam_policy.policies : k => v.id
  }
}

output "policies" {
  description = "Map of IAM policy attributes"
  value = {
    for k, v in aws_iam_policy.policies : k => {
      arn         = v.arn
      id          = v.id
      name        = v.name
      description = v.description
      path        = v.path
      policy      = v.policy
      policy_id   = v.policy_id
      tags        = v.tags
      tags_all    = v.tags_all
    }
  }
}

# IAM Group Outputs
output "group_arns" {
  description = "Map of IAM group ARNs"
  value = {
    for k, v in aws_iam_group.groups : k => v.arn
  }
}

output "group_names" {
  description = "Map of IAM group names"
  value = {
    for k, v in aws_iam_group.groups : k => v.name
  }
}

output "groups" {
  description = "Map of IAM group attributes"
  value = {
    for k, v in aws_iam_group.groups : k => {
      arn       = v.arn
      name      = v.name
      unique_id = v.unique_id
      path      = v.path
    }
  }
}

# IAM User Outputs
output "user_arns" {
  description = "Map of IAM user ARNs"
  value = {
    for k, v in aws_iam_user.users : k => v.arn
  }
}

output "user_names" {
  description = "Map of IAM user names"
  value = {
    for k, v in aws_iam_user.users : k => v.name
  }
}

output "user_unique_ids" {
  description = "Map of IAM user unique IDs"
  value = {
    for k, v in aws_iam_user.users : k => v.unique_id
  }
}

output "users" {
  description = "Map of IAM user attributes"
  value = {
    for k, v in aws_iam_user.users : k => {
      arn                  = v.arn
      name                 = v.name
      unique_id           = v.unique_id
      path                = v.path
      permissions_boundary = v.permissions_boundary
      tags                = v.tags
      tags_all            = v.tags_all
    }
  }
}

# IAM Access Key Outputs (sensitive)
output "access_keys" {
  description = "Map of IAM access key IDs"
  value = {
    for k, v in aws_iam_access_key.access_keys : k => {
      id     = v.id
      user   = v.user
      status = v.status
    }
  }
}

output "access_key_secrets" {
  description = "Map of IAM access key secrets"
  value = {
    for k, v in aws_iam_access_key.access_keys : k => v.secret
  }
  sensitive = true
}

# IAM Instance Profile Outputs
output "instance_profile_arns" {
  description = "Map of IAM instance profile ARNs"
  value = {
    for k, v in aws_iam_instance_profile.instance_profiles : k => v.arn
  }
}

output "instance_profile_names" {
  description = "Map of IAM instance profile names"
  value = {
    for k, v in aws_iam_instance_profile.instance_profiles : k => v.name
  }
}

output "instance_profiles" {
  description = "Map of IAM instance profile attributes"
  value = {
    for k, v in aws_iam_instance_profile.instance_profiles : k => {
      arn         = v.arn
      name        = v.name
      unique_id   = v.unique_id
      create_date = v.create_date
      path        = v.path
      role        = v.role
      tags        = v.tags
      tags_all    = v.tags_all
    }
  }
}

# OIDC Identity Provider Outputs
output "oidc_provider_arns" {
  description = "Map of OIDC identity provider ARNs"
  value = {
    for k, v in aws_iam_openid_connect_provider.oidc_providers : k => v.arn
  }
}

output "oidc_providers" {
  description = "Map of OIDC identity provider attributes"
  value = {
    for k, v in aws_iam_openid_connect_provider.oidc_providers : k => {
      arn             = v.arn
      url             = v.url
      client_id_list  = v.client_id_list
      thumbprint_list = v.thumbprint_list
      tags            = v.tags
      tags_all        = v.tags_all
    }
  }
}

# SAML Identity Provider Outputs
output "saml_provider_arns" {
  description = "Map of SAML identity provider ARNs"
  value = {
    for k, v in aws_iam_saml_provider.saml_providers : k => v.arn
  }
}

output "saml_providers" {
  description = "Map of SAML identity provider attributes"
  value = {
    for k, v in aws_iam_saml_provider.saml_providers : k => {
      arn                    = v.arn
      name                   = v.name
      saml_metadata_document = v.saml_metadata_document
      tags                   = v.tags
      tags_all              = v.tags_all
      valid_until           = v.valid_until
    }
  }
}