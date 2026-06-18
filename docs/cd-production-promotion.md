# Production CD promotion (reference — not scheduled)

> **Status:** Production runtime is **off** and not on the roadmap right now. Staging is the only counted pipeline. This document is a reference for *how* production could be turned on later; enabling it is an open decision, not a committed phase.

Production exists in **Git** as a mirror of staging (Kustomize overlays, Terraform, ArgoCD Application). **Runtime** (EKS cluster, deploy, ECR push) stays off — see [showcase-staging-only.md](showcase-staging-only.md).

## If/when production runtime is enabled

There is no scheduled date. Revisit this only if we explicitly decide to go multi-environment. Prerequisite either way: staging CD proven stable.

## Steps

### 1. GitHub repository variables

| Variable | Value |
|----------|-------|
| `ENABLE_PROD_CD` | `true` — enable promote job when wired |
| `PRODUCTION_HEALTH_URL` | `https://flags.example.com/health` |

### 2. Re-enable production ECR push in CI

Add this step back to [`.github/workflows/ci.yaml`](../.github/workflows/ci.yaml) after `Push to staging ECR`:

```yaml
      - name: Push to production ECR
        if: github.ref == 'refs/heads/main'
        uses: docker/build-push-action@10e90e3645eae34f1e60eeb005ba3a3d33f178e8 # v6
        with:
          context: app/backend
          push: true
          tags: |
            ${{ vars.AWS_ACCOUNT_ID }}.dkr.ecr.${{ vars.AWS_REGION }}.amazonaws.com/${{ vars.PROJECT_NAME }}-production-backend:${{ steps.tags.outputs.sha_tag }}
            ${{ vars.AWS_ACCOUNT_ID }}.dkr.ecr.${{ vars.AWS_REGION }}.amazonaws.com/${{ vars.PROJECT_NAME }}-production-backend:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

Or gate behind `vars.ENABLE_PROD_ECR == 'true'` if you prefer opt-in.

### 3. Apply production Terraform

See [infrastructure/environments/production/README.md](../infrastructure/environments/production/README.md).

### 4. Bootstrap production EKS platform

Repeat the staging bootstrap from [k8s/argocd/install-notes.md](../k8s/argocd/install-notes.md) on the production cluster:

- Istio production profile
- Ingress NGINX + cert-manager + Let's Encrypt issuer
- ArgoCD Helm install
- `backend-secrets` in namespace `production`

### 5. Register ArgoCD Application

```bash
kubectl apply -f k8s/argocd/application-production.yaml
```

### 6. Add promote job to CD workflow

Add a job (manual or automatic) after staging public health check succeeds:

1. Read the validated `sha-<commit>` from the staging bump commit
2. Update `k8s/overlays/production/kustomization.yaml` `newTag`
3. Commit `chore(cd): promote production to sha-xxx [skip ci]`
4. Wait for ArgoCD sync on production
5. `curl -f $PRODUCTION_HEALTH_URL`

Example trigger:

```yaml
promote-production:
  needs: deploy
  if: vars.ENABLE_PROD_CD == 'true'
  # workflow_dispatch for manual approval is recommended first
```

### 7. Blue/green on production (optional)

Reuse `scripts/blue-green-switch.sh` and production overlay changes mirroring staging if zero-downtime promotion is required on production.

## Rollback

- Revert the production GitOps commit
- ArgoCD history rollback: `argocd app rollback feature-flags-production`
- Keep staging as the pre-production gate — never promote a SHA that failed staging
