terraform {
  backend "s3" {
    bucket       = "devsecops-tfstate-260931184808"
    key          = "staging/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}