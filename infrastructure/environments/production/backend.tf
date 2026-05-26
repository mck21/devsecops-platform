terraform {
  backend "s3" {
    bucket       = "devsecops-tfstate-125156866917"
    key          = "production/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}