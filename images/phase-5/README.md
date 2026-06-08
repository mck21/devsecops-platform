# Phase 5 — CD & GitOps evidence

Capture screenshots after the staging CD pipeline runs end-to-end on EKS.

## Checklist

| # | File | Content |
|---|------|---------|
| 1 | `01-cd-workflow-green.png` | GitHub Actions CD workflow success with GitOps commits |
| 2 | `02-argocd-staging-synced.png` | ArgoCD UI — `feature-flags-staging` Synced + Healthy |
| 3 | `03-blue-green-switch.png` | ArgoCD or terminal during traffic switch |
| 4 | `04-virtualservice-weights.png` | `kubectl get virtualservice backend -n staging -o yaml` showing 100/0 split |
| 5 | `05-rollback-complete.png` | Rollback job after simulated health failure (optional) |

## Manual validation commands

```bash
# After merge to main
gh run list --workflow=CD --limit 3

# Cluster
kubectl get pods,virtualservice -n staging
kubectl get application feature-flags-staging -n argocd

# Health
curl -f "$STAGING_HEALTH_URL"
```

## Notes

- Dev (Minikube) CD is manual during Phase 5 — no screenshot required for phase closure.
- Production ArgoCD screenshots deferred until [docs/cd-production-promotion.md](../docs/cd-production-promotion.md) is activated.
