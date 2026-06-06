# Kubernetes Manifests

Kustomize-based manifests for the Feature Flag Service.

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

Overlays exist as scaffolding. Replace `<ACCOUNT_ID>` in `kustomization.yaml` with your AWS account ID after Phase 4 ECR push. Live deploy deferred to Phase 5.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `FailedCreate: minimum cpu usage per Container is 50m, but request is 10m` | LimitRange `min` too high for Istio sidecar — see `base/limitrange.yaml` |
| `exceeded quota: namespace-quota, limits.cpu` | Dev quota too tight during rollouts — see `overlays/dev/patch-resourcequota.yaml` |
| `P1001: Can't reach database server` | Apply `destinationrules-tcp.yaml`; ensure `holdApplicationUntilProxyStarts` on backend |
| Stale image after rebuild | Scale to 0, `minikube ssh "docker rmi -f backend:latest"`, `minikube image load backend:latest` |
