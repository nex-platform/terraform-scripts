# IAM Roles
resource "aws_iam_role" "roles" {
  for_each = var.roles

  name                 = each.key
  assume_role_policy   = each.value.assume_role_policy
  description          = lookup(each.value, "description", null)
  force_detach_policies = lookup(each.value, "force_detach_policies", false)
  max_session_duration = lookup(each.value, "max_session_duration", 3600)
  path                 = lookup(each.value, "path", "/")
  permissions_boundary = lookup(each.value, "permissions_boundary", null)

  dynamic "inline_policy" {
    for_each = lookup(each.value, "inline_policies", {})
    content {
      name   = inline_policy.key
      policy = inline_policy.value
    }
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# IAM Role Policy Attachments
resource "aws_iam_role_policy_attachment" "role_policy_attachments" {
  for_each = {
    for attachment in local.role_policy_attachments : "${attachment.role}_${attachment.policy}" => attachment
  }

  role       = aws_iam_role.roles[each.value.role].name
  policy_arn = each.value.policy
}

# IAM Policies
resource "aws_iam_policy" "policies" {
  for_each = var.policies

  name        = each.key
  description = lookup(each.value, "description", "Policy for ${each.key}")
  policy      = each.value.policy_document
  path        = lookup(each.value, "path", "/")

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# IAM Groups
resource "aws_iam_group" "groups" {
  for_each = var.groups

  name = each.key
  path = lookup(each.value, "path", "/")
}

# IAM Group Policy Attachments
resource "aws_iam_group_policy_attachment" "group_policy_attachments" {
  for_each = {
    for attachment in local.group_policy_attachments : "${attachment.group}_${attachment.policy}" => attachment
  }

  group      = aws_iam_group.groups[each.value.group].name
  policy_arn = each.value.policy
}

# IAM Group Memberships
resource "aws_iam_group_membership" "group_memberships" {
  for_each = {
    for membership in local.group_memberships : "${membership.group}_${membership.user}" => membership
  }

  name  = "${each.value.group}-membership"
  group = aws_iam_group.groups[each.value.group].name
  users = [each.value.user]
}

# IAM Users
resource "aws_iam_user" "users" {
  for_each = var.users

  name                 = each.key
  path                 = lookup(each.value, "path", "/")
  permissions_boundary = lookup(each.value, "permissions_boundary", null)
  force_destroy        = lookup(each.value, "force_destroy", false)

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# IAM User Policy Attachments
resource "aws_iam_user_policy_attachment" "user_policy_attachments" {
  for_each = {
    for attachment in local.user_policy_attachments : "${attachment.user}_${attachment.policy}" => attachment
  }

  user       = aws_iam_user.users[each.value.user].name
  policy_arn = each.value.policy
}

# IAM Access Keys
resource "aws_iam_access_key" "access_keys" {
  for_each = {
    for user_name, user_config in var.users : user_name => user_config
    if lookup(user_config, "create_access_key", false)
  }

  user = aws_iam_user.users[each.key].name
}

# IAM Instance Profiles
resource "aws_iam_instance_profile" "instance_profiles" {
  for_each = var.instance_profiles

  name = each.key
  path = lookup(each.value, "path", "/")
  role = aws_iam_role.roles[each.value.role].name

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# OIDC Identity Providers
resource "aws_iam_openid_connect_provider" "oidc_providers" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# SAML Identity Providers
resource "aws_iam_saml_provider" "saml_providers" {
  for_each = var.saml_providers

  name                   = each.key
  saml_metadata_document = each.value.saml_metadata_document

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

# Local values for flattening nested structures
locals {
  role_policy_attachments = flatten([
    for role_name, role_config in var.roles : [
      for policy in lookup(role_config, "attached_policies", []) : {
        role   = role_name
        policy = policy
      }
    ]
  ])

  group_policy_attachments = flatten([
    for group_name, group_config in var.groups : [
      for policy in lookup(group_config, "attached_policies", []) : {
        group  = group_name
        policy = policy
      }
    ]
  ])

  group_memberships = flatten([
    for group_name, group_config in var.groups : [
      for user in lookup(group_config, "members", []) : {
        group = group_name
        user  = user
      }
    ]
  ])

  user_policy_attachments = flatten([
    for user_name, user_config in var.users : [
      for policy in lookup(user_config, "attached_policies", []) : {
        user   = user_name
        policy = policy
      }
    ]
  ])
}