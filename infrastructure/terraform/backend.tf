terraform {
  backend "s3" {
    bucket         = "devsecops-tfstate-260931184808"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devsecops-tfstate-lock"
    encrypt        = true
  }
}
