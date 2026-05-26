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