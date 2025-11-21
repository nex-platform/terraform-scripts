# EKS Module

This module provisions an Amazon EKS (Elastic Kubernetes Service) cluster with node groups, supporting Kubernetes version 1.33.

## Features

- 🚀 **EKS Cluster**: Fully managed Kubernetes control plane
- 👥 **Node Groups**: Managed EC2 instances for worker nodes
- 🔐 **IAM Integration**: Proper IAM roles and policies
- 🛡️ **Security**: Configurable security groups and network access
- 📊 **Logging**: Control plane logging support
- 🔧 **Addons**: EKS addons management (CoreDNS, kube-proxy, VPC CNI)
- 🏷️ **Tagging**: Comprehensive resource tagging

## Usage

### Basic Example

```hcl
module "eks" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/eks?ref=v1.0.0"

  cluster_name = "my-eks-cluster"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]

  node_groups = {
    default = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
    }
  }

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Advanced Example

```hcl
module "eks" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/eks?ref=v1.0.0"

  cluster_name       = "production-eks-cluster"
  kubernetes_version = "1.33"
  vpc_id            = "vpc-12345678"
  subnet_ids        = ["subnet-12345678", "subnet-87654321", "subnet-11223344"]

  # Network Configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["10.0.0.0/16"]

  # Control Plane Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Authentication
  authentication_mode = "API_AND_CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true

  # Node Groups
  node_groups = {
    general = {
      desired_size   = 3
      max_size       = 6
      min_size       = 2
      instance_types = ["t3.large"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels = {
        role = "general"
      }
      tags = {
        NodeGroup = "general"
      }
    }
    
    spot = {
      desired_size   = 2
      max_size       = 10
      min_size       = 0
      instance_types = ["t3.medium", "t3.large", "t3.xlarge"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "SPOT"
      disk_size      = 30
      labels = {
        role = "spot"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      tags = {
        NodeGroup = "spot"
      }
    }
  }

  # EKS Addons
  cluster_addons = {
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
    aws-ebs-csi-driver = {
      addon_version            = null
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = null
    }
  }

  # Encryption at Rest
  cluster_encryption_config = [{
    provider_key_arn = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
    resources        = ["secrets"]
  }]

  tags = {
    Environment = "production"
    Project     = "my-project"
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
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster and node groups | `list(string)` | n/a | yes |
| vpc_id | VPC ID where the cluster security group will be provisioned | `string` | n/a | yes |
| kubernetes_version | Kubernetes version for the EKS cluster | `string` | `"1.33"` | no |
| endpoint_private_access | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `false` | no |
| endpoint_public_access | Whether the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| public_access_cidrs | List of CIDR blocks that can access the Amazon EKS public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| additional_security_group_ids | List of additional security group IDs to attach to the EKS cluster | `list(string)` | `[]` | no |
| cluster_encryption_config | Configuration block with encryption configuration for the cluster | `list(object({...}))` | `[]` | no |
| cluster_enabled_log_types | List of the desired control plane logging to enable | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| authentication_mode | The authentication mode for the cluster | `string` | `"API_AND_CONFIG_MAP"` | no |
| bootstrap_cluster_creator_admin_permissions | Whether or not to bootstrap the access config values to the cluster | `bool` | `true` | no |
| node_groups | Map of node group configurations | `map(object({...}))` | See default node group | no |
| cluster_addons | Map of cluster addon configurations to enable for the cluster | `map(object({...}))` | Default addons | no |
| create_additional_security_group | Whether to create additional security group for the cluster | `bool` | `false` | no |
| additional_security_group_rules | List of additional security group rules to add to the cluster security group | `list(object({...}))` | `[]` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster |
| cluster_endpoint | Endpoint for your Kubernetes API server |
| cluster_id | The name of the cluster |
| cluster_name | The name of the cluster |
| cluster_oidc_issuer_url | The URL on the EKS cluster for the OpenID Connect identity provider |
| cluster_platform_version | Platform version for the cluster |
| cluster_status | Status of the EKS cluster |
| cluster_version | The Kubernetes version for the cluster |
| cluster_security_group_id | Cluster security group that was created by Amazon EKS for the cluster |
| cluster_vpc_id | ID of the VPC associated with your cluster |
| cluster_iam_role_name | IAM role name associated with EKS cluster |
| cluster_iam_role_arn | IAM role ARN associated with EKS cluster |
| node_groups | Map of node group attributes |
| node_group_iam_role_name | IAM role name associated with EKS node groups |
| node_group_iam_role_arn | IAM role ARN associated with EKS node groups |
| cluster_addons | Map of cluster addon attributes |

## Node Group Configuration

The `node_groups` variable accepts a map where each key is the node group name and the value is an object with the following structure:

```hcl
node_groups = {
  "node-group-name" = {
    # Required
    desired_size   = number
    max_size       = number  
    min_size       = number
    
    # Optional
    ami_type                     = string       # Default: "AL2_x86_64"
    capacity_type               = string       # Default: "ON_DEMAND" 
    disk_size                   = number       # Default: 20
    instance_types              = list(string) # Default: ["t3.medium"]
    labels                      = map(string)  # Default: {}
    taints                      = list(object) # Default: []
    tags                        = map(string)  # Default: {}
    max_unavailable             = number       # Default: null
    max_unavailable_percentage  = number       # Default: null
    ec2_ssh_key                 = string       # Default: null
    source_security_group_ids   = list(string)# Default: []
    launch_template             = object       # Default: null
  }
}
```

## EKS Addons

The module supports the following EKS addons by default:
- **coredns**: CoreDNS for DNS resolution
- **kube-proxy**: Network proxy for Kubernetes services
- **vpc-cni**: Amazon VPC CNI plugin for pod networking

Additional addons can be configured such as:
- **aws-ebs-csi-driver**: Amazon EBS CSI driver for persistent volumes
- **aws-efs-csi-driver**: Amazon EFS CSI driver for shared file systems

## Security Considerations

- The module creates IAM roles with least-privilege policies
- Control plane logging is enabled by default for audit and security monitoring
- Encryption at rest can be configured using AWS KMS
- Network access can be restricted using security groups and CIDR blocks
- Private endpoint access can be enabled for enhanced security

## Examples

Complete examples are available in the [examples/basic](./examples/basic/) directory.

## Contributing

When contributing to this module:

1. Ensure all variables have proper descriptions and types
2. Add examples for new features
3. Update the README for any new inputs/outputs
4. Test the module with different configurations
5. Follow Terraform best practices

## License

This module is licensed under the MIT License.