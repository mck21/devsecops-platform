# Contributing Guide

> How to work with branches, commits, and pull requests in this repository.
> Every change to `main` must go through a Pull Request — no direct pushes allowed.

---

## Branch Strategy

```
main                        ← protected, production-ready code only
└── feat/<short-name>       ← new features
└── fix/<short-name>        ← bug fixes
└── docs/<short-name>       ← documentation only changes
└── chore/<short-name>      ← maintenance (deps, config, cleanup)
└── test/<short-name>       ← adding or fixing tests
```

---

## Step-by-Step Workflow

### 1. Always start from an updated main

```bash
git checkout main
git pull origin main
```

### 2. Create a new branch

```bash
git checkout -b feat/<short-description>

# Examples:
git checkout -b feat/terraform-remote-backend
git checkout -b feat/vpc-networking-module
git checkout -b feat/nestjs-health-endpoint
git checkout -b docs/readme-architecture-diagram
git checkout -b fix/hpa-memory-threshold
```

### 3. Make your changes, then stage and commit

```bash
git add .
git commit -m "feat: add terraform remote backend (s3 + dynamodb)"
```

### 4. Push the branch to GitHub

```bash
# First push on a new branch
git push -u origin feat/<short-description>

# Subsequent pushes on the same branch
git push
```

### 5. Open a Pull Request on GitHub

- Go to your repo on GitHub
- You'll see a yellow banner: **"Compare & pull request"** → click it
- Set the title to match your commit message
- Add a short description of what changed and why
- Click **Create pull request**

### 5b. Wait for CI checks (Phase 4+)

Every PR must pass the automated checks before merge:

| Check | Workflow | What it does |
|-------|----------|--------------|
| CI | `.github/workflows/ci.yaml` | ESLint, Jest (coverage), Docker build, Trivy, ECR push (staging) |
| Security | `.github/workflows/security.yaml` | Gitleaks, Checkov, Trivy fs, OWASP Dependency Check |
| Terraform | `.github/workflows/terraform.yaml` | `terraform fmt`, validate, plan |
| SonarCloud | GitHub App | Quality gate on `app/backend/src/` |

Fix failing checks on your branch and push again — GitHub re-runs the workflows automatically.

### 6. Merge the PR

- Review the changes in the **Files changed** tab
- Click **Merge pull request** → **Confirm merge**
- Delete the branch after merging (GitHub will offer this)

### 7. Sync your local main

```bash
git checkout main
git pull origin main
```

---

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description in lowercase>
```

| Type | When to use |
|---|---|
| `feat` | Adding new functionality |
| `fix` | Fixing a bug |
| `docs` | Documentation changes only |
| `chore` | Maintenance, config, dependencies |
| `test` | Adding or modifying tests |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `ci` | Changes to CI/CD pipeline files |

### Examples

```
feat: add vpc and networking modules
feat: add eks cluster and node groups
fix: correct subnet cidr block overlap
docs: add deployment guide for minikube and eks
chore: update gitignore for terraform lock files
test: add k6 load testing scripts
ci: add trivy image scanning stage to ci pipeline
refactor: extract eks module from main terraform config
```

### Rules
- Use lowercase
- No period at the end
- Keep it under 72 characters
- Use the imperative mood: "add", "fix", "update" — not "added", "fixed", "updated"

---

## Full Example: Adding a New Feature

```bash
# 1. Start from clean main
git checkout main
git pull origin main

# 2. Create branch
git checkout -b feat/vpc-networking-module

# 3. Do your work...
# edit files, write code, etc.

# 4. Stage and commit
git add .
git commit -m "feat: add vpc and networking modules"

# 5. Push branch
git push -u origin feat/vpc-networking-module

# 6. Open PR on GitHub → review → merge

# 7. Clean up locally
git checkout main
git pull origin main
git branch -d feat/vpc-networking-module
```

---

## Branch Naming Quick Reference

| What you're doing | Branch name |
|---|---|
| Terraform remote backend | `feat/terraform-remote-backend` |
| VPC and networking | `feat/vpc-networking-module` |
| IAM roles | `feat/iam-roles-security-groups` |
| EKS cluster | `feat/eks-cluster-node-groups` |
| ECR repository | `feat/ecr-repository` |
| Minikube base setup | `feat/minikube-base-setup` |
| ArgoCD install | `feat/argocd-installation` |
| Istio service mesh | `feat/istio-service-mesh` |
| NestJS backend | `feat/nestjs-feature-flag-api` |
| CI pipeline | `feat/github-actions-ci-pipeline` |
| CD / GitOps pipeline | `feat/argocd-cd-pipeline` |
| Agent / status docs | `docs/agent-guide` |
| SonarQube setup | `feat/sonarqube-quality-gate` |
| Security hardening | `feat/kubernetes-security-hardening` |
| Monitoring stack | `feat/prometheus-grafana-loki` |
| Resilience tests | `test/resilience-testing-scripts` |
| README update | `docs/readme-architecture-diagram` |

---

## Rules Summary

- ✅ Always branch off `main`
- ✅ One feature per branch
- ✅ Commit messages follow Conventional Commits
- ✅ Always open a PR — never push directly to `main`
- ✅ Pull `main` after every merge before creating a new branch
- ❌ Never force push to `main`
- ❌ Never commit secrets, `.env` files, or `*.tfvars` with real values