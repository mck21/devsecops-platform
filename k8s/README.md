# Kubernetes Manifests

Kustomize-based manifests for the Feature Flag Service.

**Agent docs:** [AGENTS.md](../AGENTS.md) · **Phase status:** [STATUS.md](../STATUS.md) · **Troubleshooting:** [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

## Structure

```
k8s/
├── base/              # env-agnostic resources (no namespace)
├── overlays/
│   ├── dev/           # Minikube — deploy now
│   ├── staging/       # EKS scaffolding
│   └── production/    # EKS scaffolding
├── blue-green/        # Istio blue/green skeleton (Phase 5 automation)
├── argocd/            # Application CRDs (wired in Phase 5)
└── namespaces/        # Platform namespaces
```

## Phase Scope

| Path | Status | Notes |
|------|--------|-------|
| `overlays/dev/` | **Live** — deploy on Minikube today | Full stack: backend, postgres, redis, HPA |
| `overlays/staging/` | Scaffolding | ECR image placeholder; live deploy in Phase 5 |
| `overlays/production/` | Scaffolding | Same as staging |
| `blue-green/` | Scaffolding | Traffic switch automation in Phase 5 |
| `argocd/` | Scaffolding | Auto-sync wired in Phase 5 |

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

## Staging / Production

Overlays point at ECR (`125156866917.dkr.ecr.us-east-1.amazonaws.com/mck21-devsecops-{staging,production}-backend`). CI pushes `sha-<commit>` tags in Phase 4; live deploy deferred to Phase 5.

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
