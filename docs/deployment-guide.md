# Deployment Guide

Covers local **Minikube** (dev) and cloud **EKS** (staging). Production runtime is
off during showcase — see [showcase-staging-only.md](showcase-staging-only.md).

## Prerequisites

- `kubectl`, `kustomize` (or `kubectl kustomize`), `helm`, `aws` CLI, `docker`,
  `bun`, `istioctl`, `minikube` (local), `argocd` CLI (optional).
- AWS account `125156866917`, region `us-east-1`.

---

## A. Local — Minikube (dev)

```bash
minikube start --cpus=4 --memory=8192 --driver=docker
minikube addons enable ingress
minikube addons enable metrics-server

# Istio (demo profile) + injection on dev
istioctl install --set profile=demo -y
kubectl label namespace dev istio-injection=enabled --overwrite

kubectl apply -f k8s/namespaces/namespaces.yaml

# Build + load app image
docker build -t backend:latest ./app/backend
minikube image load backend:latest

# Create the local secret from the template (do not commit real values)
kubectl apply -f k8s/base/secret.yaml -n dev

kubectl apply -k k8s/overlays/dev
kubectl get pods -n dev
kubectl port-forward svc/backend -n dev 3000:80
curl http://localhost:3000/health
```

Gotchas (Prisma v7, Istio TCP, image caching, LimitRange): [../TROUBLESHOOTING.md](../TROUBLESHOOTING.md).

Optional add-ons on dev:
```bash
# Monitoring (Phase 7)
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring -f monitoring/prometheus/values-dev.yaml
kubectl apply -k monitoring
# Policies (Phase 6) — audit mode on dev
helm install kyverno kyverno/kyverno -n policy-system
kubectl apply -k k8s/kyverno/policies
kubectl apply -k k8s/security
```

---

## B. Cloud — EKS (staging)

### 1. Infrastructure (Terraform)

```bash
cd infrastructure/environments/staging
terraform init && terraform apply
aws eks update-kubeconfig --name mck21-devsecops-staging-eks --region us-east-1
kubectl get nodes
```

### 2. Platform bootstrap

Follow [../k8s/argocd/install-notes.md](../k8s/argocd/install-notes.md):
Istio (production profile), Ingress NGINX, cert-manager + Let's Encrypt, ArgoCD,
`backend-secrets` (or External Secrets), then register the staging Application.

### 3. Security, monitoring, DR add-ons

```bash
# Phase 6
helm install kyverno kyverno/kyverno -n policy-system
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --set installCRDs=true
kubectl apply -f k8s/external-secrets/staging.yaml
# Phase 7
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f monitoring/prometheus/values-eks.yaml
helm install loki grafana/loki -n monitoring -f monitoring/loki/values-eks.yaml
helm install promtail grafana/promtail -n monitoring -f monitoring/promtail/values.yaml
# Phase 8
helm install velero vmware-tanzu/velero -n velero --create-namespace   # see k8s/velero/install-notes.md
kubectl apply -f k8s/velero/schedules.yaml
```

Or let ArgoCD manage them via the Applications in [../k8s/argocd/](../k8s/argocd/)
(`application-platform-security.yaml`, `application-kyverno-policies.yaml`,
`application-monitoring.yaml`).

### 4. Trigger the pipeline

```bash
git checkout main && git pull
git commit --allow-empty -m "chore: trigger staging deploy"
git push origin main
gh run list --workflow=CI --limit 3
gh run list --workflow=CD --limit 3
```

CI builds/scans/signs/pushes to ECR; CD bumps the idle blue/green color, ArgoCD
syncs, health check runs, traffic switches. Rollback is automatic on failure.

---

## C. Production

Off during showcase. To enable later, follow
[cd-production-promotion.md](cd-production-promotion.md). Manifests are a Git
mirror of staging and stay aligned in every PR.

## Verify a deploy

```bash
kubectl get pods,virtualservice -n staging
kubectl get application -n argocd
kubectl get clusterpolicy            # Kyverno
kubectl get servicemonitor -n monitoring
curl -f "$STAGING_HEALTH_URL"
```
