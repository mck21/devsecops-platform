# Agent Guide

Entry point for AI agents working on this repository. Read this file first, then [STATUS.md](STATUS.md) for phase progress.

---

## Project Snapshot

**What this is:** A portfolio-grade DevSecOps platform on AWS demonstrating IaC, Kubernetes, CI/CD, GitOps, security, and observability end-to-end.

**Application domain:** Feature Flag Service — manage feature toggles per environment without redeploying. Real-world equivalents: LaunchDarkly, Unleash, Flipt.

**Why Redis matters:** Flags are written rarely but read on every client request. `GET /api/flags/{key}` hits Redis first (cache), PostgreSQL on miss. This read path justifies HPA scaling.

| Item | Value |
|------|-------|
| AWS Account ID | `125156866917` |
| Terraform state bucket | `devsecops-tfstate-125156866917` |
| App runtime | NestJS 11 + Bun + TypeScript |
| Data layer | PostgreSQL (Prisma 7) + Redis |
| Dev cluster | Minikube (local) |
| Staging / Production | EKS on AWS |

**Current phase:** Phase 5 implemented (staging-first CD). **Next:** Validate CD on EKS staging, then Phase 6 — Security Hardening. See [STATUS.md](STATUS.md).

---

## Repository Map

```
devsecops-platform/
├── app/backend/          # NestJS Feature Flag API (active)
├── app/frontend/         # Empty — reserved for future UI
├── infrastructure/       # Terraform modules + staging/production envs
├── k8s/                  # Kustomize manifests (base + overlays + blue-green + argocd)
├── .github/workflows/    # ci.yaml, cd.yaml, security.yaml, terraform.yaml
├── scripts/              # blue/green CD automation (Phase 5)
├── docs/                 # Placeholder — full docs in Phase 9
├── images/phase-N/       # Screenshot evidence per phase
├── docker-compose.yml    # Local dev stack (postgres + redis + backend)
├── PLAN.md               # Full roadmap (1056 lines — use STATUS.md for current state)
├── STATUS.md             # Phase tracker
├── TROUBLESHOOTING.md    # Deploy runbook (Istio, Prisma, Minikube)
└── CONTRIBUTE.md         # Git workflow and commit conventions
```

---

## Working Conventions

- Branch off `main`; one feature per branch. Naming: `feat/`, `fix/`, `docs/`, `chore/`, `ci/`, `test/`
- Conventional Commits: `feat:`, `fix:`, `docs:`, etc. — see [CONTRIBUTE.md](CONTRIBUTE.md)
- **Never commit secrets.** `k8s/base/secret.yaml` is a template only; create `backend-secrets` locally from it
- **Never commit** `.env`, `*.tfvars` with real values, or credentials
- Kubernetes path is `k8s/` (not `kubernetes/`)
- Namespace is set by Kustomize overlays, not hardcoded in base manifests

---

## How to Run Locally

### Docker Compose (application only)

```bash
docker compose up --build
curl http://localhost:3000/health
curl http://localhost:3000/metrics
```

### Minikube (full K8s stack)

Prerequisites: Minikube running with Istio injection enabled on `dev` namespace. See [k8s/README.md](k8s/README.md).

```bash
kubectl apply -f k8s/namespaces/namespaces.yaml
docker build -t backend:latest ./app/backend
minikube image load backend:latest
kubectl apply -k k8s/overlays/dev
kubectl get pods -n dev
kubectl port-forward svc/backend -n dev 3000:80
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness/readiness — checks PostgreSQL + Redis |
| GET | `/metrics` | Prometheus metrics |
| POST | `/api/flags` | Create flag |
| GET | `/api/flags` | List flags (`?env=production` filter) |
| GET | `/api/flags/{key}` | Get flag (Redis-cached) |
| PATCH | `/api/flags/{key}/toggle` | Toggle flag for environment |
| DELETE | `/api/flags/{key}` | Delete flag |
| GET | `/api/audit` | Audit log (create, toggle, delete) |

---

## Known Gotchas (read before K8s or Istio work)

These issues were hit during Phase 3 deployment. Do not assume an app bug until these are ruled out.

**Full runbook:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — symptom index, diagnostic commands, and step-by-step fixes.

Summary:

- **Prisma v7** — `datasource.url` in `prisma.config.ts`; copy to Docker image; dummy `DATABASE_URL` at build time
- **NestJS build** — output is `dist/src/main.js`, not `dist/main.js`
- **Minikube images** — `imagePullPolicy: Never` + `latest` causes stale images; force-remove before reload
- **Istio + TCP** — postgres/redis need `tcp-` port names, `appProtocol: tcp`, DestinationRules, and `holdApplicationUntilProxyStarts`
- **LimitRange** — `min` must be `10m` CPU / `40Mi` memory for Istio sidecar injection
- **ResourceQuota** — rollouts with sidecars need higher CPU limits (dev patch: `16`)

---

## Phase Boundaries — What NOT to Do Yet

| Deferred to | Do not implement yet |
|-------------|---------------------|
| Phase 6 | Kyverno policies, NetworkPolicy, External Secrets, manifest `securityContext` |
| Phase 7 | Grafana dashboards, Loki, custom Prometheus ServiceMonitors |
| Phase 9 | Full `docs/`, ADRs, architecture diagrams |
| End of PLAN | Production CD auto-sync — see [docs/cd-production-promotion.md](docs/cd-production-promotion.md) |

**Phase 5 (staging-first):** CD auto-deploys to **staging EKS only**. Dev is manual. Run EKS bootstrap once: [k8s/argocd/install-notes.md](k8s/argocd/install-notes.md). Set GitHub vars `EKS_CLUSTER_NAME`, `STAGING_HEALTH_URL`.

---

## Key Files Quick Reference

| Task | File(s) |
|------|---------|
| API business logic | `app/backend/src/flags/`, `app/backend/src/audit/` |
| Prisma schema | `app/backend/prisma/schema.prisma` |
| Prisma config (v7) | `app/backend/prisma.config.ts` |
| Docker build | `app/backend/Dockerfile`, `app/backend/docker-entrypoint.sh` |
| K8s base manifests | `k8s/base/` |
| Dev overlay (Minikube) | `k8s/overlays/dev/` |
| Istio TCP fix | `k8s/base/destinationrules-tcp.yaml` |
| HPA (min 1 on dev) | `k8s/base/hpa.yaml`, `k8s/overlays/dev/patch-hpa.yaml` |
| Terraform modules | `infrastructure/modules/` |
| Terraform staging/prod | `infrastructure/environments/staging/`, `production/` |
| Phase roadmap | `PLAN.md` |
| Phase progress | `STATUS.md` |
| CI / CD workflows | `.github/workflows/ci.yaml`, `.github/workflows/cd.yaml` |
| CD scripts | `scripts/gitops-bump.sh`, `scripts/blue-green-switch.sh`, `scripts/rollback.sh` |
| SonarCloud config | `sonar-project.properties` |
| GitHub OIDC (Terraform) | `infrastructure/modules/github-oidc/` |

---

## When Stuck

1. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — deploy runbook (Istio, Prisma, Minikube)
2. [k8s/README.md](k8s/README.md) — quick troubleshooting table
3. [PLAN.md](PLAN.md) — full phase requirements and acceptance criteria
4. [images/phase-N/](images/) — expected outcomes as screenshots
5. [app/backend/README.md](app/backend/README.md) — NestJS structure and request lifecycle

---

## Tech Stack Note — CI (Phase 4, done)

The application is **NestJS / TypeScript / Jest / Bun**, not Python:

- Lint: ESLint via `bun run lint:ci` (not ruff)
- Tests: Jest with coverage via `bun run test:ci` (not pytest)
- SonarCloud: TypeScript sources under `app/backend/src/`; quality gate via GitHub App check on free plan

Some older references in [PLAN.md](PLAN.md) may still mention Python — treat NestJS/TypeScript as the source of truth.
