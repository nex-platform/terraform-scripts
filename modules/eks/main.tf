# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.additional_security_group_ids
  }

  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids

  # AMI Configuration
  ami_type        = lookup(each.value, "ami_type", "AL2_x86_64")
  capacity_type   = lookup(each.value, "capacity_type", "ON_DEMAND")
  disk_size       = lookup(each.value, "disk_size", 20)
  instance_types  = lookup(each.value, "instance_types", ["t3.medium"])

  # Scaling Configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update Configuration
  dynamic "update_config" {
    for_each = lookup(each.value, "max_unavailable", null) != null ? [1] : []
    content {
      max_unavailable = lookup(each.value, "max_unavailable", null)
    }
  }

  dynamic "update_config" {
    for_each = lookup(each.value, "max_unavailable_percentage", null) != null ? [1] : []
    content {
      max_unavailable_percentage = lookup(each.value, "max_unavailable_percentage", null)
    }
  }

  # Remote Access
  dynamic "remote_access" {
    for_each = lookup(each.value, "ec2_ssh_key", null) != null ? [1] : []
    content {
      ec2_ssh_key               = lookup(each.value, "ec2_ssh_key", null)
      source_security_group_ids = lookup(each.value, "source_security_group_ids", [])
    }
  }

  # Launch Template
  dynamic "launch_template" {
    for_each = lookup(each.value, "launch_template", null) != null ? [each.value.launch_template] : []
    content {
      id      = lookup(launch_template.value, "id", null)
      name    = lookup(launch_template.value, "name", null)
      version = launch_template.value.version
    }
  }

  # Taints
  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])
    content {
      key    = taint.value.key
      value  = lookup(taint.value, "value", null)
      effect = taint.value.effect
    }
  }

  # Labels
  labels = merge(
    lookup(each.value, "labels", {}),
    {
      "node-group" = each.key
    }
  )

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${var.cluster_name}-${each.key}"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# EKS Addons
resource "aws_eks_addon" "addons" {
  for_each = var.cluster_addons

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = each.key
  addon_version            = lookup(each.value, "addon_version", null)
  resolve_conflicts        = lookup(each.value, "resolve_conflicts", "OVERWRITE")
  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  tags = var.tags
}

# Security Group for additional rules if needed
resource "aws_security_group" "cluster_additional" {
  count = var.create_additional_security_group ? 1 : 0

  name_prefix = "${var.cluster_name}-additional-"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-additional-sg"
    }
  )
}

resource "aws_security_group_rule" "cluster_additional_ingress" {
  count = var.create_additional_security_group ? length(var.additional_security_group_rules) : 0

  type                     = "ingress"
  from_port                = var.additional_security_group_rules[count.index].from_port
  to_port                  = var.additional_security_group_rules[count.index].to_port
  protocol                 = var.additional_security_group_rules[count.index].protocol
  cidr_blocks              = lookup(var.additional_security_group_rules[count.index], "cidr_blocks", [])
  source_security_group_id = lookup(var.additional_security_group_rules[count.index], "source_security_group_id", null)
  security_group_id        = aws_security_group.cluster_additional[0].id
  description              = lookup(var.additional_security_group_rules[count.index], "description", null)
}