variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "image_retention_count" {
  description = "Number of images to keep in ECR"
  type        = number
  default     = 10
}

variable "repositories" {
  description = "List of repository names to create"
  type        = list(string)
  default     = ["backend", "frontend"]
}