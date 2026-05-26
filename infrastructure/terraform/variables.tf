variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "mck21-devsecops"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
