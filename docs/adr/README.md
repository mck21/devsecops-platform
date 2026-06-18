# Architecture Decision Records

ADRs capture significant, hard-to-reverse decisions: the context, the choice, and
its trade-offs. Format follows [MADR](https://adr.github.io/)-lite.

## Format

```markdown
# ADR-00X: Title
## Status
Accepted / Superseded / Deprecated
## Context
What problem were we solving?
## Decision
What did we decide?
## Consequences
What becomes easier or harder?
```

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [001](001-argocd-over-fluxcd.md) | ArgoCD over Flux CD | Accepted |
| [002](002-eks-over-ecs.md) | EKS over ECS | Accepted |
| [003](003-kustomize-for-app-helm-for-infra.md) | Kustomize for app, Helm for platform | Accepted |
| [004](004-github-actions-over-jenkins.md) | GitHub Actions over Jenkins | Accepted |
| [005](005-istio-tradeoffs.md) | Keep Istio despite operational cost | Accepted |
| [006](006-feature-flag-service-domain.md) | Feature Flag Service as demo domain | Accepted |
| [007](007-staging-first-cd.md) | Staging-first CD; production off | Accepted |
