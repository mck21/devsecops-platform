locals {
  name = "${var.project_name}-${var.environment}"
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "main" {
  name     = "${local.name}-eks"
  version  = var.cluster_version
  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    security_group_ids      = [var.eks_cluster_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enable control plane logging
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Name        = "${local.name}-eks"
    Project     = var.project_name
    Environment = var.environment
  }
}

# --- OIDC Provider ---
# Enables IAM Roles for Service Accounts (IRSA)
# Allows pods to assume IAM roles without long-lived credentials

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name        = "${local.name}-eks-oidc"
    Project     = var.project_name
    Environment = var.environment
  }
}

# --- Node Group ---
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name}-nodes"
  node_role_arn   = var.eks_nodes_role_arn

  # Nodes run in private subnets
  subnet_ids = var.private_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  # Use latest EKS-optimized Amazon Linux 2 AMI
  ami_type = "AL2_x86_64"

  tags = {
    Name        = "${local.name}-nodes"
    Project     = var.project_name
    Environment = var.environment
  }

  # Ensure IAM role policies are attached before node group is created
  depends_on = [
    aws_eks_cluster.main
  ]
}

# --- CI/CD cluster access (GitHub Actions kubectl) ---
resource "aws_eks_access_entry" "cicd" {
  count = var.cicd_role_arn != "" ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.cicd_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cicd_admin" {
  count = var.cicd_role_arn != "" ? 1 : 0

  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.cicd[0].principal_arn

  access_scope {
    type = "cluster"
  }
}