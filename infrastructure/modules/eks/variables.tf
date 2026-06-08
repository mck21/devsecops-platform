variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "eks_cluster_role_arn" {
  description = "ARN of the IAM role for the EKS control plane"
  type        = string
}

variable "eks_nodes_role_arn" {
  description = "ARN of the IAM role for the EKS worker nodes"
  type        = string
}

variable "eks_cluster_sg_id" {
  description = "Security group ID for the EKS control plane"
  type        = string
}

variable "eks_nodes_sg_id" {
  description = "Security group ID for the EKS worker nodes"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where worker nodes will run"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the control plane ENIs"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "cicd_role_arn" {
  description = "IAM role ARN for GitHub Actions CD (EKS access entry). Empty disables access entry."
  type        = string
  default     = ""
}