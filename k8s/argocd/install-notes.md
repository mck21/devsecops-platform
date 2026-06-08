# ArgoCD Installation

## Dev (Minikube)

Installed via official stable manifest:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Access:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

- URL: https://localhost:8080
- User: `admin`
- Password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`

Register the dev app (optional, local GitOps):

```bash
kubectl apply -f k8s/argocd/application-dev.yaml
```

## Staging (EKS) — Phase 5 bootstrap

Prerequisites: `kubectl` context pointing at the staging EKS cluster (`mck21-devsecops-staging-eks`).

### 1. Namespaces

```bash
kubectl apply -f k8s/namespaces/namespaces.yaml
```

### 2. Istio (production profile)

```bash
istioctl install --set profile=production -y
kubectl label namespace staging istio-injection=enabled --overwrite
```

See [k8s/istio/istio-notes.md](../istio/istio-notes.md).

### 3. Ingress NGINX

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```

### 4. cert-manager + Let's Encrypt issuer

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true

kubectl apply -f k8s/platform/cluster-issuer-letsencrypt.yaml
```

### 5. Application secrets (never commit real values)

```bash
kubectl apply -f k8s/base/secret.yaml -n staging
# Or create from template with env-specific DATABASE_URL:
# kubectl create secret generic backend-secrets -n staging \
#   --from-literal=DATABASE_URL='postgresql://...'
```

### 6. ArgoCD (Helm)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --set configs.params.server.insecure=true
```

Initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Port-forward UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 7. Connect Git repository

In ArgoCD UI → Settings → Repositories → Connect repo:

- URL: `https://github.com/mck21/devsecops-platform.git`
- Public repo: no credentials required; private repo: PAT or deploy key

Or CLI:

```bash
argocd login localhost:8080 --username admin --password <password> --insecure
argocd repo add https://github.com/mck21/devsecops-platform.git
```

### 8. Register staging Application (auto-sync)

```bash
# Validate manifests first
kubectl apply -k k8s/overlays/staging --dry-run=server

kubectl apply -f k8s/argocd/application-staging.yaml
```

Do **not** apply `application-production.yaml` until production CD is enabled (end of PLAN).

### 9. GitHub Actions CD variables

Set repository variables in GitHub → Settings → Variables:

| Variable | Example |
|----------|---------|
| `STAGING_HEALTH_URL` | `https://flags.staging.example.com/health` (or ALB hostname) |
| `EKS_CLUSTER_NAME` | `mck21-devsecops-staging-eks` |

Ensure branch protection allows GitHub Actions to push GitOps commits to `main`, or configure `CD_BOT_TOKEN` secret.

## Production (EKS)

ArgoCD and app registration deferred until multi-env promotion is enabled. See [docs/cd-production-promotion.md](../../docs/cd-production-promotion.md).
