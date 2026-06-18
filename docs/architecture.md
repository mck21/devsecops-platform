# Architecture

End-to-end design of the DevSecOps platform and its demo workload, the Feature
Flag Service. Diagram sources live in [diagrams/](diagrams/).

## System overview

```mermaid
flowchart TB
    subgraph Dev[Local dev]
      compose[Docker Compose] 
      mk[Minikube + Istio + ArgoCD]
    end
    subgraph CICD[GitHub]
      ci[CI: lint, test, Sonar, Trivy, build, Cosign sign, ECR push]
      cd[CD: GitOps tag bump, blue/green switch, rollback]
    end
    subgraph AWS
      ecr[(ECR)]
      subgraph EKSstaging[EKS staging]
        argocd[ArgoCD]
        app[Feature Flag API blue/green]
        data[(PostgreSQL + Redis)]
        mesh[Istio]
        policy[Kyverno]
        obs[Prometheus/Grafana/Loki]
        eso[External Secrets -> Secrets Manager]
      end
      mirror[[EKS production - Git mirror, OFF]]
    end
    compose -. alt .- mk
    ci --> ecr
    ci --> cd
    cd --> argocd
    argocd --> app
    ecr -.image.-> app
    app --> data
    app -.metrics.-> obs
    policy -. admission .-> app
```

## Environments

| Env | Cluster | Manifests | CD | Runtime |
|-----|---------|-----------|----|---------|
| dev | Minikube | `k8s/overlays/dev` | manual | local |
| staging | EKS | `k8s/overlays/staging` | automatic (ArgoCD) | **on** |
| production | EKS | `k8s/overlays/production` | deferred | **off** (Git mirror) |

One set of base manifests; per-environment differences are Kustomize overlays.

## Application (Feature Flag Service)

```mermaid
flowchart LR
    client[Client] -->|GET /api/flags/key| api[NestJS API]
    api -->|hit| redis[(Redis)]
    api -->|miss| pg[(PostgreSQL)]
    pg --> redis
    api -->|PATCH /toggle| pg
    api -->|invalidate| redis
    api -->|audit write| pg
```

- **NestJS modules:** `flags`, `audit`, `health`, `cache`, `prisma`.
- **Redis** is the architectural core: flag reads happen on every client request,
  which is what justifies the HPA. Writes (toggles) are rare and invalidate cache.
- **PostgreSQL** is the source of truth for flag definitions + the audit log.
- Observability: `/metrics` (prom-client), structured JSON logs (pino) with
  request IDs, Istio mesh metrics/traces.

## CI/CD flow

```mermaid
sequenceDiagram
    participant Dev
    participant GH as GitHub Actions
    participant ECR
    participant Git
    participant Argo as ArgoCD (EKS)
    Dev->>GH: push / merge to main
    GH->>GH: lint, test, SonarCloud gate
    GH->>GH: Trivy scan, docker build
    GH->>ECR: push sha-<commit> + sign (Cosign keyless)
    GH->>Git: CD bumps idle color image tag [skip ci]
    Argo->>Git: detect drift
    Argo->>Argo: sync idle color, wait healthy
    GH->>Argo: blue/green traffic switch (VirtualService)
    GH-->>Git: on failure, rollback traffic + revert tag
```

## Security layers (Phase 6)

- **Build:** Trivy image scan, Cosign keyless signing.
- **Admission:** Kyverno (no privileged, resource limits, non-root, no `:latest`,
  hardened securityContext, verify Cosign signature).
- **Runtime:** Pod Security Standards (baseline enforce / restricted audit),
  hardened `securityContext`, NetworkPolicy default-deny, RBAC least-privilege.
- **Secrets:** External Secrets Operator + AWS Secrets Manager on EKS; local
  template on dev.

## Observability (Phase 7)

Prometheus scrapes app `/metrics` + Istio mesh + cluster; Grafana dashboards;
Loki/Promtail logs; SLOs with multi-window burn-rate alerts. See
[../docs/sre.md](sre.md) and [../monitoring/README.md](../monitoring/README.md).

## Resilience (Phase 8)

Velero backups (S3 + EBS snapshots), k6 load/HPA tests, documented failure-
injection drills. See [disaster-recovery.md](disaster-recovery.md) and
[resilience-testing.md](resilience-testing.md).

## Key decisions

See the ADRs in [adr/](adr/): ArgoCD over Flux, EKS over ECS, Kustomize for app /
Helm for infra, GitHub Actions over Jenkins, Istio trade-offs, and the
Feature-Flag-Service domain choice.
