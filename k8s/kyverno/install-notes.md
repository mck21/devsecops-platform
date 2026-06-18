# Kyverno — install & policy notes

Policy-as-code admission control for both clusters. Kyverno runs in the
`policy-system` namespace (already created in `k8s/namespaces/namespaces.yaml`).

## Install (Helm)

```bash
helm repo add kyverno https://kyverno.github.io/kyverno
helm repo update

helm install kyverno kyverno/kyverno \
  --namespace policy-system \
  --create-namespace \
  --set admissionController.replicas=1   # 3 on production for HA
```

## Apply policies

```bash
kubectl apply -k k8s/kyverno/policies
kubectl get clusterpolicy
```

## Policies

| Policy | Effect | Scope |
|--------|--------|-------|
| `disallow-privileged-containers` | Enforce | dev, staging, production |
| `require-resource-limits` | Enforce | dev, staging, production |
| `require-run-as-non-root` | Enforce (staging/prod), Audit (dev) | app namespaces |
| `disallow-latest-tag` | Enforce | staging, production |
| `require-securitycontext` | Enforce (prod), Audit (dev/staging) | `app: backend` pods |
| `verify-image-signatures` | Enforce | staging, production |

> **Audit vs Enforce:** dev runs the stricter checks in `Audit` mode so local
> iteration is never blocked; production enforces. See policy `failureAction`
> overrides per rule.

## Image signature verification

`verify-image-signatures` uses **keyless** Cosign verification: CI signs the
image through GitHub Actions OIDC (Sigstore/Fulcio), and Kyverno checks the
signature + Rekor transparency log entry before admitting the pod. Update the
`subject`/`issuer` if the workflow path or repo changes. See
[../../docs/security.md](../../docs/security.md).

## Demo — policy blocking a bad pod

```bash
kubectl run bad --image=nginx:latest -n staging   # blocked: latest tag + no limits
kubectl run priv --image=nginx:1.27 -n staging \
  --overrides='{"spec":{"containers":[{"name":"priv","image":"nginx:1.27","securityContext":{"privileged":true}}]}}'
```
