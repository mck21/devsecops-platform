variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tfstate_bucket_name" {
  description = "S3 bucket name for Terraform remote state (CI plan read access)"
  type        = string
  default     = ""
}