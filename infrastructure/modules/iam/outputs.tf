output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_nodes_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_nodes.arn
}

output "cicd_role_arn" {
  description = "ARN of the CI/CD IAM role for GitHub Actions"
  value       = aws_iam_role.cicd.arn
}