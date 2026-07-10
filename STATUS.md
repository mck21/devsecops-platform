# Project Status

Phase tracker for the DevSecOps platform. All phases complete.

**Active work:** None — Phases 1–9 complete and validated on staging EKS. The AWS environment has been decommissioned; the evidence in `images/phase-N/` is final.  
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
| 4 | CI Pipeline (GitHub Actions, SonarCloud, ECR) | **Done** | `.github/workflows/`, `sonar-project.properties` |
| 5 | CD & GitOps (ArgoCD sync, blue/green automation) | **Done** (staging-first) | `.github/workflows/cd.yaml`, `scripts/`, `images/phase-5/` |
| 6 | Security hardening (Kyverno, Cosign, NetworkPolicy, External Secrets) | **Done** | `k8s/security/`, `k8s/kyverno/`, `k8s/external-secrets/`, securityContext in deployments, Cosign in `ci.yaml`, `images/phase-6/` |
| 7 | Monitoring & SRE (Prometheus, Grafana, Loki) | **Done** | `monitoring/`, `docs/sre.md`, `images/phase-7/` |
| 8 | DR & resilience (Velero, k6) | **Done** | `k8s/velero/`, `tests/k6/`, `scripts/resilience-test.sh`, `docs/disaster-recovery.md`, `docs/resilience-testing.md`, `images/phase-8/` |
| 9 | Documentation, ADRs, diagrams, cost docs | **Done** | `docs/` (architecture, deployment-guide, security, monitoring, sonarqube, cost), `docs/adr/`, `docs/diagrams/` |

> **Phases 5–8 were validated live on staging EKS** (ArgoCD sync, blue/green,
> Kyverno enforcement, dashboards, pod recovery) before the AWS environment was
> decommissioned. The screenshots in `images/phase-N/` are the final evidence set
> — no further captures are possible. All manifests pass `kubectl kustomize` +
> `yamllint`.

---

## Showcase mode — Git vs runtime

**Scope:** Staging was the only environment with a working pipeline. Production is **off** — kept in Git as a mirror of staging only. The staging AWS runtime has since been decommissioned; the Git manifests and captured evidence document the working state.

| Layer | Staging | Production |
|-------|---------|------------|
| **Git** | Active source | **Mirror** of staging — kept aligned |
| **Runtime** | Validated on EKS + CD, since decommissioned | **Off** — never lifted |
| **Pipeline (CI/CD)** | Counted as the working pipeline | Excluded — no build, push, or deploy |

**To re-lift staging:** follow [docs/showcase-staging-only.md](docs/showcase-staging-only.md) (terraform apply **staging only**, bootstrap EKS staging, push to `main`).

---

## Phase 5 — Implementation Details (staging-first)

Automatic CD targets **staging EKS only** — staging is the only counted pipeline for now. Dev (Minikube) remains manual. Production is **off**: no CI build/push, no CD deploy. Production **manifests** stay in Git as a mirror of staging; turning production runtime on later is an undecided next step — reference: [docs/cd-production-promotion.md](docs/cd-production-promotion.md).

### Delivered

- [`.github/workflows/cd.yaml`](.github/workflows/cd.yaml) — post-CI GitOps bump, rollout health check, traffic switch, rollback
- [`scripts/`](scripts/) — `gitops-bump.sh`, `blue-green-switch.sh`, `blue-green-health.sh`, `rollback.sh`
- [`k8s/overlays/staging/`](k8s/overlays/staging/) — blue/green overlay, sync waves, `cd-active-color` ConfigMap
- [`k8s/overlays/production/`](k8s/overlays/production/) — Git mirror of staging (blue/green, production ECR, HA patches)
- [`k8s/argocd/install-notes.md`](k8s/argocd/install-notes.md) — EKS staging bootstrap runbook
- Terraform EKS access entry for staging `cicd` role ([`infrastructure/modules/eks/`](infrastructure/modules/eks/))
- CI: `[skip ci]` guard; **no production ECR push** until final promotion phase

### GitHub variables required

| Variable | Example |
|----------|---------|
| `EKS_CLUSTER_NAME` | `mck21-devsecops-staging-eks` |
| `STAGING_HEALTH_URL` | `https://<alb-hostname>/health` (optional — leave empty until Ingress ready) |

Optional: secret `CD_BOT_TOKEN` if branch protection blocks `GITHUB_TOKEN`.

### Validation (complete)

- [x] One-time EKS staging bootstrap per install notes
- [x] `terraform apply` in staging for EKS access entry
- [x] Merge to `main` → CI → CD green
- [x] Evidence captured in [`images/phase-5/`](images/phase-5/) (ArgoCD sync, blue/green VirtualService)

---

## Blockers / Deferred

| Item | Reason | Target |
|------|--------|--------|
| Production runtime (EKS, CD) | Off — Git mirror only; staging was the validated pipeline | Not planned; reference [docs/cd-production-promotion.md](docs/cd-production-promotion.md) |
| Dev automated CD | Minikube not reachable from GitHub-hosted runners | Manual dev deploy |
| Diagram PNG exports | Mermaid sources committed (`docs/diagrams/*.mmd`); GitHub renders them inline, PNGs only needed for slides/PDFs | Optional |
| Additional runtime evidence | AWS environment decommissioned — no cluster access; existing `images/phase-N/` screenshots are final | Closed |

---

## Environment Strategy

| Environment | Kubernetes (runtime) | Git manifests | CD |
|-------------|----------------------|---------------|-----|
| `dev` | Minikube (local) | `overlays/dev/` | Manual |
| `staging` | EKS (AWS) — validated, since decommissioned | `overlays/staging/` | **Automatic** (when lifted) |
| `production` | Off — never lifted | `overlays/production/` mirror | None (excluded) |
