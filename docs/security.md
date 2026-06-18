# Security

Defense-in-depth across build, supply chain, admission, runtime, and secrets.

## Layers at a glance

| Stage | Control | Where |
|-------|---------|-------|
| Source | Secret scanning (Gitleaks), SAST + Quality Gate (SonarCloud) | CI |
| Build | Image vuln scan (Trivy), IaC scan (Checkov) | CI |
| Supply chain | Cosign keyless signing; Kyverno signature verification | CI + admission |
| Admission | Kyverno ClusterPolicies | `policy-system` |
| Runtime | Pod Security Standards, securityContext, NetworkPolicy, RBAC | app namespaces |
| Secrets | External Secrets Operator + AWS Secrets Manager | EKS |

## Container hardening (Phase 3 + 6)

- Dockerfile: multi-stage, non-root `appuser` (uid 1001), minimal `oven/bun:1-slim`, no secrets baked in.
- Manifest `securityContext` (backend deployments — base + blue + green):
  - pod: `runAsNonRoot`, `runAsUser/Group: 1001`, `fsGroup: 1001`, `seccompProfile: RuntimeDefault`
  - container: `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`
  - writable `/tmp` via emptyDir (compatible with read-only root fs)
  - `automountServiceAccountToken: false`

## Pod Security Standards

Namespace labels (`k8s/namespaces/namespaces.yaml`): **enforce baseline**,
**audit/warn restricted** on `dev`, `staging`, `production`. Baseline is enforced
(not restricted) because in-namespace postgres/redis need writable filesystems;
the backend app independently meets the restricted bar via its securityContext.
For a production runtime, prefer managed RDS/ElastiCache and enforce restricted.

## Kyverno policies (`k8s/kyverno/policies/`)

| Policy | Mode |
|--------|------|
| disallow-privileged-containers | Enforce (all app ns) |
| require-resource-limits | Enforce |
| require-run-as-non-root | Enforce (staging/prod), Audit (dev) |
| disallow-latest-tag | Enforce (staging/prod) |
| require-securitycontext | Enforce (prod), Audit (dev/staging) |
| verify-image-signatures | Enforce (staging/prod) |

Install + demo: [../k8s/kyverno/install-notes.md](../k8s/kyverno/install-notes.md).

## Supply chain — Cosign

CI signs every pushed image **keylessly** via GitHub Actions OIDC
(Sigstore/Fulcio), recording the signature in the Rekor transparency log. Kyverno
`verify-image-signatures` admits only images whose signature matches the expected
workflow identity (`.github/workflows/ci.yaml@refs/heads/main`). This blocks
unsigned or tampered images from running.

```bash
cosign verify \
  --certificate-identity-regexp 'https://github.com/mck21/devsecops-platform/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  125156866917.dkr.ecr.us-east-1.amazonaws.com/mck21-devsecops-staging-backend:<sha>
```

## Network policies

Default-deny ingress per app namespace, plus explicit allows: ingress-nginx →
backend:3000, monitoring → backend:3000 (scrape), backend → postgres:5432 /
redis:6379, and DNS + Istiod egress. See `k8s/security/network-policies.yaml`.

## RBAC

Least-privilege: cluster-wide read-only `platform-readonly` for auditors;
namespaced `app-developer` (read/write on dev, read-only on staging/production —
prod changes go through GitOps only). Subjects are groups mapped from AWS IAM /
OIDC. See `k8s/security/rbac.yaml`.

## Secrets management

| Env | Backend |
|-----|---------|
| dev (Minikube) | local `secret.yaml` template (never real values) |
| staging/production (EKS) | AWS Secrets Manager via External Secrets Operator (IRSA) |

See [../k8s/external-secrets/install-notes.md](../k8s/external-secrets/install-notes.md).

## CI security scans

`ci.yaml` (Trivy, build) plus the documented Phase 4 scanners (Gitleaks, Checkov,
OWASP Dependency Check) and the SonarCloud Quality Gate with security hotspots.
See [sonarqube.md](sonarqube.md).
