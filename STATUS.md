# Project Status

Phase tracker for the DevSecOps platform. Updated after Phase 5 implementation.

**Active work:** Phase 5 validation on EKS staging (screenshots)  
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
| 5 | CD & GitOps (ArgoCD sync, blue/green automation) | **Implemented** (staging-first) | `.github/workflows/cd.yaml`, `scripts/`, `images/phase-5/` |
| 6 | Security hardening (Kyverno, Cosign, NetworkPolicy) | Not started | — |
| 7 | Monitoring & SRE (Prometheus, Grafana, Loki) | Not started | `monitoring/` placeholder |
| 8 | DR & resilience (Velero, k6) | Not started | — |
| 9 | Documentation, ADRs, diagrams, cost docs | Not started | `docs/` placeholder |

---

## Phase 5 — Implementation Details (staging-first)

Automatic CD targets **staging EKS only**. Dev (Minikube) remains manual. Production CD deferred — see [docs/cd-production-promotion.md](docs/cd-production-promotion.md).

### Delivered

- [`.github/workflows/cd.yaml`](.github/workflows/cd.yaml) — post-CI GitOps bump, rollout health check, traffic switch, rollback
- [`scripts/`](scripts/) — `gitops-bump.sh`, `blue-green-switch.sh`, `blue-green-health.sh`, `rollback.sh`
- [`k8s/overlays/staging/`](k8s/overlays/staging/) — blue/green overlay, sync waves, `cd-active-color` ConfigMap
- [`k8s/argocd/install-notes.md`](k8s/argocd/install-notes.md) — EKS staging bootstrap runbook
- Terraform EKS access entry for staging `cicd` role ([`infrastructure/modules/eks/`](infrastructure/modules/eks/))
- CI: `[skip ci]` guard; production ECR gated by `ENABLE_PROD_ECR` (default off)

### GitHub variables required

| Variable | Example |
|----------|---------|
| `EKS_CLUSTER_NAME` | `mck21-devsecops-staging-eks` |
| `STAGING_HEALTH_URL` | `https://<alb-hostname>/health` |

Optional: `ENABLE_PROD_ECR=true`, secret `CD_BOT_TOKEN` if branch protection blocks `GITHUB_TOKEN`.

### Pending validation

- [ ] One-time EKS staging bootstrap per install notes
- [ ] `terraform apply` in staging for EKS access entry
- [ ] Merge to `main` → CI → CD green
- [ ] Screenshots in [`images/phase-5/`](images/phase-5/) per README checklist

---

## Blockers / Deferred

| Item | Reason | Target |
|------|--------|--------|
| Production CD | Staging-first cost/risk strategy | [docs/cd-production-promotion.md](docs/cd-production-promotion.md) |
| Dev automated CD | Minikube not reachable from GitHub-hosted runners | Manual dev deploy |
| Architecture diagram, full deployment guide | Portfolio polish | Phase 9 |
| Grafana dashboards | Monitoring stack not installed | Phase 7 |

---

## Environment Strategy

| Environment | Kubernetes | CD |
|-------------|------------|-----|
| `dev` | Minikube (local) | Manual |
| `staging` | EKS (AWS) | **Automatic** (merge to `main`) |
| `production` | EKS (AWS) | Deferred |
