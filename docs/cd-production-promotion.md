# Production CD promotion (deferred)

Production deploy is **intentionally disabled** during Phase 5 build to keep the pipeline green and AWS costs low. Staging is the sole automated CD target until the rest of the PLAN is complete.

## When to enable

After Phase 5 staging CD is stable and remaining PLAN phases are done (or when you explicitly choose to turn on multi-env).

## Steps

### 1. GitHub repository variables

| Variable | Value |
|----------|-------|
| `ENABLE_PROD_ECR` | `true` — restores production ECR push on `main` in CI |
| `ENABLE_PROD_CD` | `true` — enable when the promote job is wired (future) |
| `PRODUCTION_HEALTH_URL` | `https://flags.example.com/health` |

### 2. Bootstrap production EKS platform

Repeat the staging bootstrap from [k8s/argocd/install-notes.md](../k8s/argocd/install-notes.md) on the production cluster:

- Istio production profile
- Ingress NGINX + cert-manager + Let's Encrypt issuer
- ArgoCD Helm install
- `backend-secrets` in namespace `production`

### 3. Register ArgoCD Application

```bash
kubectl apply -f k8s/argocd/application-production.yaml
```

### 4. Add promote job to CD workflow

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

### 5. Blue/green on production (optional)

Reuse `scripts/blue-green-switch.sh` and production overlay changes mirroring staging if zero-downtime promotion is required on production.

## Rollback

- Revert the production GitOps commit
- ArgoCD history rollback: `argocd app rollback feature-flags-production`
- Keep staging as the pre-production gate — never promote a SHA that failed staging
