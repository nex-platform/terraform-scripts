# Cluster Outputs
output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_id" {
  description = "The name of the cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.main.status
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_vpc_id" {
  description = "ID of the VPC associated with your cluster"
  value       = aws_eks_cluster.main.vpc_config[0].vpc_id
}

# IAM Role Outputs
output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = aws_iam_role.cluster.unique_id
}

# Node Group Outputs
output "node_groups" {
  description = "Map of node group attributes"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      arn               = v.arn
      id                = v.id
      status            = v.status
      capacity_type     = v.capacity_type
      disk_size         = v.disk_size
      instance_types    = v.instance_types
      ami_type          = v.ami_type
      labels            = v.labels
      resources         = v.resources
      scaling_config    = v.scaling_config
      update_config     = v.update_config
      version           = v.version
      release_version   = v.release_version
      remote_access     = v.remote_access
      taints           = v.taint
    }
  }
}

output "node_group_iam_role_name" {
  description = "IAM role name associated with EKS node groups"
  value       = aws_iam_role.node_group.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN associated with EKS node groups"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role for node groups"
  value       = aws_iam_role.node_group.unique_id
}

# EKS Addons Outputs
output "cluster_addons" {
  description = "Map of cluster addon attributes"
  value = {
    for k, v in aws_eks_addon.addons : k => {
      arn               = v.arn
      id                = v.id
      status            = v.status
      addon_version     = v.addon_version
      configuration_values = v.configuration_values
      created_at        = v.created_at
      modified_at       = v.modified_at
    }
  }
}

# Security Group Outputs
output "additional_security_group_id" {
  description = "ID of the additional security group created for the cluster"
  value       = var.create_additional_security_group ? aws_security_group.cluster_additional[0].id : null
}

output "additional_security_group_arn" {
  description = "ARN of the additional security group created for the cluster"
  value       = var.create_additional_security_group ? aws_security_group.cluster_additional[0].arn : null
}

# OIDC Identity Provider
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Identity Provider if enabled"
  value       = try(aws_iam_openid_connect_provider.oidc_provider[0].arn, null)
}

# Additional useful outputs for kubectl configuration
output "kubeconfig_certificate_authority_data" {
  description = "Certificate authority data for kubeconfig"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}