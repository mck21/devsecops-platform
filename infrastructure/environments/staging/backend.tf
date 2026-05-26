terraform {
  backend "s3" {
    bucket       = "devsecops-tfstate-125156866917"
    key          = "staging/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}