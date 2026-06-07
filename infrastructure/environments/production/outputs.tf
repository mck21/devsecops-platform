output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "eks_cluster_role_arn" {
  value = module.iam.eks_cluster_role_arn
}

output "eks_nodes_role_arn" {
  value = module.iam.eks_nodes_role_arn
}

output "eks_cluster_sg_id" {
  value = module.security_groups.eks_cluster_sg_id
}

output "eks_nodes_sg_id" {
  value = module.security_groups.eks_nodes_sg_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "cicd_role_arn" {
  value = module.iam.cicd_role_arn
}