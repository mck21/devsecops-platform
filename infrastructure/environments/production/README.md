# Production environment (Terraform)

Valid Terraform for the production AWS stack — **Git mirror** of [../staging/](../staging/) with production sizing and a separate VPC CIDR.

## Status: off (current)

Production runtime is **off** and not scheduled. Staging is the only environment with a working pipeline. This directory is a Git mirror only.

**Do not run `terraform apply` here.**

- No production EKS cluster required for green CI/CD
- No AWS cost from production infra
- Code remains in the repo to demonstrate multi-environment IaC design

When [staging](../staging/) modules or variables change, keep this directory aligned (same modules, production-specific values).

## Differences from staging

| Setting | Staging | Production |
|---------|---------|------------|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` |
| Node type | `t3.medium` | `t3.large` |
| Node min | 1 | 2 |
| ECR retention | 10 images | 20 images |
| GitHub OIDC | Created in staging apply | Uses account-level provider |

## When to apply

There is no scheduled date. Apply only if we explicitly decide to enable production runtime — see [docs/cd-production-promotion.md](../../docs/cd-production-promotion.md).

```bash
cd infrastructure/environments/production
terraform init
terraform plan
terraform apply   # only when promoting to production runtime
```

## State

Backend key: `production/terraform.tfstate` in bucket `devsecops-tfstate-125156866917`.
