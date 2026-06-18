# External Secrets Operator (ESO) — install & notes

On EKS (staging/production), `backend-secrets` is sourced from **AWS Secrets
Manager** via ESO instead of the committed `secret.yaml` template (which is for
Minikube/dev only).

## Install (Helm)

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --set installCRDs=true
```

## Prerequisites (Terraform)

- IRSA roles `mck21-devsecops-<env>-external-secrets` with `secretsmanager:GetSecretValue`
  scoped to `arn:aws:secretsmanager:us-east-1:125156866917:secret:mck21-devsecops/<env>/*`.
- Secret `mck21-devsecops/<env>/backend` with JSON keys `DATABASE_URL`, `REDIS_URL`.

## Apply

```bash
kubectl apply -f k8s/external-secrets/staging.yaml      # staging
kubectl apply -f k8s/external-secrets/production.yaml   # only if prod runtime is enabled
kubectl get externalsecret -n staging
```

ESO reconciles the `ExternalSecret` into a native `backend-secrets` Secret that
the deployment already references via `secretKeyRef`. When the AWS secret rotates,
ESO re-syncs within `refreshInterval` (1h) — see the secret-rotation resilience
test in [../../docs/resilience-testing.md](../../docs/resilience-testing.md).

## Dev (Minikube)

Dev keeps using the local `k8s/base/secret.yaml` template — no AWS dependency.
Do **not** apply the ESO manifests against Minikube.
