# Project Status

Phase tracker for the DevSecOps platform. Updated after Phase 4 completion.

**Active work:** Phase 5 — CD Pipeline & GitOps  
**Agent entry point:** [AGENTS.md](AGENTS.md)  
**Deploy runbook:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)  
**Full roadmap:** [PLAN.md](PLAN.md)

---

## Phase Summary

| Phase | Focus | Status | Evidence |
|-------|-------|--------|----------|
| Pre-Work | Repo setup, `.gitignore`, README skeleton | Done | Repo structure, [README.md](README.md), [CONTRIBUTE.md](CONTRIBUTE.md) |
| 1 | Terraform & AWS (VPC, EKS, ECR, IAM) | Done | `infrastructure/`, `images/phase-1/` |
| 2 | Kubernetes base (Minikube: Istio, ArgoCD, Ingress) | Done (Minikube) | `k8s/namespaces/`, `images/phase-2/`, install notes in `k8s/argocd/`, `k8s/istio/` |
| 3 | Feature Flag Service + K8s manifests | **Done** | `app/backend/`, `k8s/`, `images/phase-3/` |
| 4 | CI Pipeline (GitHub Actions, SonarCloud, ECR) | **Done** | `.github/workflows/`, `sonar-project.properties`, `images/phase-4/` |
| 5 | CD & GitOps (ArgoCD sync, blue/green automation) | Not started | Scaffolding in `k8s/argocd/`, `k8s/blue-green/` |
| 6 | Security hardening (Kyverno, Cosign, NetworkPolicy) | Not started | — |
| 7 | Monitoring & SRE (Prometheus, Grafana, Loki) | Not started | `monitoring/` placeholder |
| 8 | DR & resilience (Velero, k6) | Not started | — |
| 9 | Documentation, ADRs, diagrams, cost docs | Not started | `docs/` placeholder |

---

## Phase 3 — Completion Details

All criteria met. See [PLAN.md § Phase 3 Completion Criteria](PLAN.md) for the full checklist (marked `[x]`).

### Application

- NestJS API with flags, audit, health, metrics modules
- Redis cache on flag reads; PostgreSQL source of truth + audit log
- Structured JSON logging (pino) with request IDs
- Docker Compose local stack; multi-stage Dockerfile with non-root user

### Kubernetes — dev (Minikube)

- `kubectl apply -k k8s/overlays/dev` deploys backend, postgres, redis, HPA
- LimitRange, ResourceQuota, ServiceAccount, Istio TCP DestinationRules applied
- HPA: `minReplicas: 1` (dev patch), `maxReplicas: 10` (base)

### Kubernetes — scaffolding (not live-deployed)

- `k8s/overlays/staging/` and `k8s/overlays/production/` with ECR image refs (CI-validated)
- `k8s/argocd/application-{dev,staging,production}.yaml`
- `k8s/blue-green/` (deployments + VirtualService + DestinationRule)

### Screenshots

Located in `images/phase-3/`:

| File | Content |
|------|---------|
| `01-docker-compose-running.png` | Docker Compose stack up |
| `02-post-create-flag.png` | POST /api/flags |
| `03-patch-toggle-flag.png` | PATCH toggle |
| `04-get-audit-history.png` | GET /api/audit |
| `05-get-prometheus-metrics.png` | GET /metrics |
| `06-health-checks.png` | GET /health |
| `07-k8s-pods-dev.png` | Pods running in dev namespace |

---

## Phase 4 — Completion Details

All criteria met. Pipeline green on PR #16 with OIDC push to ECR staging.

### CI / CD workflows

- [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml) — lint → test → Docker build → Trivy → ECR push (OIDC, staging; production on `main`)
- [`.github/workflows/security.yaml`](.github/workflows/security.yaml) — Gitleaks, Checkov (soft-fail), Trivy fs, OWASP Dependency Check
- [`.github/workflows/terraform.yaml`](.github/workflows/terraform.yaml) — fmt, validate, plan (staging + production matrix)
- [`sonar-project.properties`](sonar-project.properties) — org `mck21`, project `mck21_devsecops-platform`
- SonarCloud quality gate via GitHub App check (Automatic Analysis on free plan)

### Infrastructure & config

- [`infrastructure/modules/github-oidc/`](infrastructure/modules/github-oidc/) — GitHub OIDC provider (apply via staging)
- IAM `cicd` role: ECR push + S3 state read + `ReadOnlyAccess` for `terraform plan`
- Backend CI: `lint:ci`, `test:ci`; Jest LCOV → `app/backend/coverage/lcov.info`
- K8s overlays: ECR image names aligned with Terraform (`mck21-devsecops-*-backend`)
- GitHub Actions pinned to full commit SHAs; `id-token: write` at job level

### Screenshots

Located in `images/phase-4/`:

| File | Content |
|------|---------|
| `01-sonarqube-cloud-passed.png` | SonarCloud Quality Gate passed |
| `02-build-complete.png` | CI build job complete |
| `03-action-success.png` | GitHub Actions workflow success |
| `04-pipeline-checks-passed.png` | PR with all checks green |
| `05-ecr-sha.png` | ECR image with `sha-<commit>` tag |

---

## Active Work — Phase 5

**Goal:** Merge to main automatically deploys to Minikube (dev) and EKS (staging/prod) via ArgoCD.

**Prerequisites from Phase 4:** CI pushes images to ECR; CD updates image tags in `k8s/overlays/`.

See [PLAN.md § Phase 5](PLAN.md) for full requirements.

---

## Blockers / Deferred

| Item | Reason | Target Phase |
|------|--------|--------------|
| Live EKS app deploy | CI pushes to ECR; CD wiring pending | 5 |
| ArgoCD auto-sync | CD pipeline not built | 5 |
| EKS platform components (Ingress, Cert Manager on EKS) | Partially done in Phase 2; full parity deferred | 2 EKS + 5 |
| `infrastructure/environments/dev/` | Empty by design — dev runs on Minikube | N/A |
| Architecture diagram, full deployment guide | Portfolio polish | 9 |
| Grafana dashboards | Monitoring stack not installed | 7 |

---

## Environment Strategy

| Environment | Kubernetes | Status |
|-------------|------------|--------|
| `dev` | Minikube (local) | App deployed and validated |
| `staging` | EKS (AWS) | CI validated (ECR push); app deploy in Phase 5 |
| `production` | EKS (AWS) | CI validated; app deploy in Phase 5 |
