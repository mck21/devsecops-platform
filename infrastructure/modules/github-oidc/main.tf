# Account-level GitHub Actions OIDC provider (apply once via staging environment).

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03fa88697c4d5940853aa769b57",
  ]

  tags = {
    Name    = "github-actions-oidc"
    Project = var.project_name
  }
}
