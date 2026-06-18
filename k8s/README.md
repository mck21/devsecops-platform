# Kubernetes Manifests

Kustomize-based manifests for the Feature Flag Service.

**Agent docs:** [AGENTS.md](../AGENTS.md) · **Phase status:** [STATUS.md](../STATUS.md) · **Troubleshooting:** [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

## Structure

```
k8s/
├── base/              # env-agnostic resources (no namespace)
├── overlays/
│   ├── dev/           # Minikube — deploy manually
│   ├── staging/       # EKS — GitOps CD target (Phase 5)
│   └── production/    # EKS — Git mirror of staging (runtime OFF)
├── blue-green/        # Istio blue/green (staging + production overlays)
├── argocd/            # Application CRDs
├── platform/          # EKS platform manifests (cert-manager issuer)
└── namespaces/        # Platform namespaces
```

## Phase Scope

| Path | Status | Notes |
|------|--------|-------|
| `overlays/dev/` | **Live** — manual Minikube | Full stack: backend, postgres, redis, HPA |
| `overlays/staging/` | **Live runtime** — ArgoCD + CD | Blue/green, ECR, sync waves |
| `overlays/production/` | **Off** — Git mirror, no runtime deploy | Same structure as staging; HA patches, `flags.example.com` |
| `blue-green/` | Wired in staging + production overlays | Traffic switch via `scripts/blue-green-switch.sh` |
| `argocd/` | Staging Application on cluster | Bootstrap: [argocd/install-notes.md](argocd/install-notes.md) |

## Deploy to Minikube (dev)

```bash
# 1. Ensure namespaces exist
kubectl apply -f k8s/namespaces/namespaces.yaml

# 2. Build and load image into Minikube
docker build -t backend:latest ./app/backend
kubectl scale deployment/backend -n dev --replicas=0 2>/dev/null || true
minikube ssh "docker rmi -f backend:latest" 2>/dev/null || true
minikube image load backend:latest

# 3. Apply dev overlay
kubectl apply -k k8s/overlays/dev

# 4. Verify
kubectl get pods -n dev
kubectl get hpa -n dev
kubectl port-forward svc/backend -n dev 3000:80
curl http://localhost:3000/health
```

## Ingress (optional)

Add to `/etc/hosts`: `127.0.0.1 flags.dev.local` and run `minikube tunnel`.

## Staging (EKS) — GitOps CD

**Full runbook:** [docs/showcase-staging-only.md](../docs/showcase-staging-only.md) · **Bootstrap:** [k8s/argocd/install-notes.md](argocd/install-notes.md)

After bootstrap, merge to `main` triggers:

1. CI builds and pushes `sha-<commit>` to staging ECR
2. CD workflow bumps idle blue/green color tag in `k8s/overlays/staging/`
3. ArgoCD syncs → health check → Istio traffic switch

Manual validation:

```bash
kubectl apply -k k8s/overlays/staging --dry-run=server
kubectl get pods,virtualservice -n staging
kubectl get application feature-flags-staging -n argocd
```

GitHub variables: `EKS_CLUSTER_NAME`, `STAGING_HEALTH_URL`.

## Production (Git mirror — off)

[`k8s/overlays/production/`](overlays/production/) mirrors staging (blue/green, sync waves, production ECR). Production runtime is **off** and not scheduled — staging is the only working pipeline. No `terraform apply production`, no `application-production.yaml` on cluster. Reference if it's ever turned on: [docs/cd-production-promotion.md](../docs/cd-production-promotion.md).

When staging overlay changes, update production overlay in the same PR to keep the mirror aligned.

## Troubleshooting

Quick reference — full runbook: [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

| Symptom | Fix |
|---------|-----|
| `FailedCreate: minimum cpu usage per Container is 50m, but request is 10m` | LimitRange `min` too high for Istio sidecar — see `base/limitrange.yaml` |
| `exceeded quota: namespace-quota, limits.cpu` | Dev quota too tight during rollouts — see `overlays/dev/patch-resourcequota.yaml` |
| `P1001: Can't reach database server` | Apply `base/destinationrules-tcp.yaml`; ensure `holdApplicationUntilProxyStarts: true` on backend deployment |
| Istio treats Postgres/Redis as HTTP | Name service ports with `tcp-` prefix and set `appProtocol: tcp` — see `base/postgres.yaml`, `base/redis.yaml` |
| Stale image after rebuild | Scale to 0, `minikube ssh "docker rmi -f backend:latest"`, `minikube image load backend:latest` |
| Prisma config / migrate errors | See [TROUBLESHOOTING.md § Prisma v7](../TROUBLESHOOTING.md#prisma-v7) |
| CD workflow fails on EKS | See [TROUBLESHOOTING.md § EKS staging CD](../TROUBLESHOOTING.md#eks-staging-cd-phase-5) |
