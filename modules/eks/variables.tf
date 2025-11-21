# Required Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node groups"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the cluster security group will be provisioned"
  type        = string
}

# Optional Variables - Cluster Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

variable "cluster_enabled_log_types" {
  description = "List of the desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Whether or not to bootstrap the access config values to the cluster"
  type        = bool
  default     = true
}

# Node Groups Configuration
variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    desired_size   = number
    max_size       = number
    min_size       = number
    ami_type       = string
    capacity_type  = string
    disk_size      = number
    instance_types = list(string)
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags                         = map(string)
    max_unavailable              = number
    max_unavailable_percentage   = number
    ec2_ssh_key                  = string
    source_security_group_ids    = list(string)
    launch_template = object({
      id      = string
      name    = string
      version = string
    })
  }))
  default = {
    default = {
      desired_size               = 2
      max_size                   = 4
      min_size                   = 1
      ami_type                   = "AL2_x86_64"
      capacity_type              = "ON_DEMAND"
      disk_size                  = 20
      instance_types             = ["t3.medium"]
      labels                     = {}
      taints                     = []
      tags                       = {}
      max_unavailable            = null
      max_unavailable_percentage = null
      ec2_ssh_key                = null
      source_security_group_ids  = []
      launch_template            = null
    }
  }
}

# EKS Addons
variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    addon_version            = string
    resolve_conflicts        = string
    service_account_role_arn = string
  }))
  default = {
    coredns = {
      addon_version            = null
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
    }
    kube-proxy = {
      addon_version            = null
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
    }
    vpc-cni = {
      addon_version            = null
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
    }
  }
}

# Additional Security Group
variable "create_additional_security_group" {
  description = "Whether to create additional security group for the cluster"
  type        = bool
  default     = false
}

variable "additional_security_group_rules" {
  description = "List of additional security group rules to add to the cluster security group"
  type = list(object({
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = list(string)
    source_security_group_id = string
    description              = string
  }))
  default = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}