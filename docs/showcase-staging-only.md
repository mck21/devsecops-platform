# Showcase — staging-only runtime

This portfolio project uses a **Git vs runtime** split for production:

| Layer | Staging | Production |
|-------|---------|------------|
| **Git** (manifests, Terraform) | Active source | **Mirror** — kept aligned with staging |
| **Runtime** (AWS, EKS, CD) | **Lifted** for showcase | **Off** — not lifted; next steps undecided |

Staging is the only environment with a working pipeline right now. You only need **staging** running for green CI + CD and Phase 5 screenshots.

---

## Before your first push (one-time)

### 1. Terraform — staging only

```bash
cd infrastructure/environments/staging
terraform init
terraform apply
```

Do **not** run `terraform apply` in `infrastructure/environments/production/`. Production is off; that code stays valid in Git as a mirror only — see [infrastructure/environments/production/README.md](../infrastructure/environments/production/README.md).

### 2. Configure kubectl

```bash
aws eks update-kubeconfig \
  --name mck21-devsecops-staging-eks \
  --region us-east-1

kubectl get nodes   # all Ready
```

### 3. Bootstrap EKS staging (cluster platform)

Follow [k8s/argocd/install-notes.md](../k8s/argocd/install-notes.md) steps 1–8:

- Namespaces, Istio, Ingress NGINX, cert-manager, `backend-secrets`
- ArgoCD Helm + repo connection
- `kubectl apply -f k8s/argocd/application-staging.yaml`

Do **not** apply `k8s/argocd/application-production.yaml` — production runtime is off. See [cd-production-promotion.md](cd-production-promotion.md) only if production is ever turned on.

### 4. GitHub repository variables

| Variable | Value |
|----------|-------|
| `AWS_ACCOUNT_ID` | `125156866917` |
| `AWS_REGION` | `us-east-1` |
| `PROJECT_NAME` | `mck21-devsecops` |
| `EKS_CLUSTER_NAME` | `mck21-devsecops-staging-eks` |
| `STAGING_HEALTH_URL` | Leave empty until Ingress works, or `http(s)://<alb-host>/health` |

Optional: secret `CD_BOT_TOKEN` if branch protection blocks `GITHUB_TOKEN` GitOps pushes.

### 5. Branch protection

Allow GitHub Actions to push `[skip ci]` GitOps commits to `main`, or use `CD_BOT_TOKEN`.

---

## Trigger pipeline

```bash
git checkout main && git pull
git commit --allow-empty -m "chore: trigger staging cd validation"
git push origin main
```

Expected flow:

1. **CI** — lint, test, build, Trivy, push image to **staging ECR only**
2. **CD** — bump idle color tag → ArgoCD sync → health check → traffic switch

Monitor:

```bash
gh run list --workflow=CI --limit 3
gh run list --workflow=CD --limit 3
```

---

## Keeping production in Git aligned

When you change [k8s/overlays/staging/](../k8s/overlays/staging/), review [k8s/overlays/production/](../k8s/overlays/production/) in the same PR:

- Same blue/green structure and sync waves
- Production-specific diffs: replicas (3), resources, ingress host (`flags.example.com`), ECR repo name

No cluster deploy required for production YAML updates during showcase.

---

## What production would need if ever turned on

Production runtime is off and not scheduled. If we later decide to enable it, see [cd-production-promotion.md](cd-production-promotion.md):

- `terraform apply` production
- Bootstrap production EKS
- Re-enable production ECR push in CI
- CD promote job + `application-production.yaml`

---

## Phase 5 screenshots

After CI + CD are green, capture evidence per [images/phase-5/README.md](../images/phase-5/README.md).

Troubleshooting: [TROUBLESHOOTING.md § EKS staging CD](../TROUBLESHOOTING.md#eks-staging-cd-phase-5).
