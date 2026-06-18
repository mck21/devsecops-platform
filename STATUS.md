# Project Status

Phase tracker for the DevSecOps platform. Updated after Phase 5 implementation.

**Active work:** Phases 6–9 built as code/manifests/docs; pending live EKS validation + screenshots  
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
| 6 | Security hardening (Kyverno, Cosign, NetworkPolicy, External Secrets) | **Implemented** | `k8s/security/`, `k8s/kyverno/`, `k8s/external-secrets/`, securityContext in deployments, Cosign in `ci.yaml` |
| 7 | Monitoring & SRE (Prometheus, Grafana, Loki) | **Implemented** | `monitoring/`, `docs/sre.md` |
| 8 | DR & resilience (Velero, k6) | **Implemented** | `k8s/velero/`, `tests/k6/`, `scripts/resilience-test.sh`, `docs/disaster-recovery.md`, `docs/resilience-testing.md` |
| 9 | Documentation, ADRs, diagrams, cost docs | **Implemented** | `docs/` (architecture, deployment-guide, security, monitoring, sonarqube, cost), `docs/adr/`, `docs/diagrams/` |

> **Phases 6–9 are built as code/manifests/docs.** Live validation (EKS deploy,
> screenshots, `terraform apply`) is the remaining manual step and is intentionally
> deferred. All new manifests pass `kubectl kustomize` + `yamllint`.

---

## Showcase mode — Git vs runtime

**Scope:** Staging is the only environment with a working pipeline right now. Production is **off** — kept in Git as a mirror of staging only. Whether/when to lift production runtime is an open decision, not a committed phase.

| Layer | Staging | Production |
|-------|---------|------------|
| **Git** | Active source | **Mirror** of staging — kept aligned |
| **Runtime** | EKS + CD on every `main` push | **Off** — not lifted; next steps TBD |
| **Pipeline (CI/CD)** | Counted as the working pipeline | Excluded — no build, push, or deploy |

**Before screenshots:** follow [docs/showcase-staging-only.md](docs/showcase-staging-only.md) (terraform apply **staging only**, bootstrap EKS staging, push to `main`).

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

### Pending validation

- [ ] One-time EKS staging bootstrap per install notes
- [ ] `terraform apply` in staging for EKS access entry
- [ ] Merge to `main` → CI → CD green
- [ ] Screenshots in [`images/phase-5/`](images/phase-5/) per README checklist

---

## Blockers / Deferred

| Item | Reason | Target |
|------|--------|--------|
| Production runtime (EKS, CD) | Off for now — Git mirror only; staging is the working pipeline | TBD — decide next steps; reference [docs/cd-production-promotion.md](docs/cd-production-promotion.md) |
| Dev automated CD | Minikube not reachable from GitHub-hosted runners | Manual dev deploy |
| Diagram PNG exports | Mermaid sources committed (`docs/diagrams/*.mmd`); render deferred with screenshots | Manual |
| Live EKS validation of Phases 6–9 | Manifests/Helm values committed; not yet applied to a cluster | Manual |

---

## Environment Strategy

| Environment | Kubernetes (runtime) | Git manifests | CD |
|-------------|----------------------|---------------|-----|
| `dev` | Minikube (local) | `overlays/dev/` | Manual |
| `staging` | EKS (AWS) | `overlays/staging/` | **Automatic** |
| `production` | Off — not lifted | `overlays/production/` mirror | None (excluded; next steps TBD) |
