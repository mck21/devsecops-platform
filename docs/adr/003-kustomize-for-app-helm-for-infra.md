# ADR-003: Kustomize for app manifests, Helm for platform components

## Status
Accepted

## Context
We need to template per-environment app config and also install large third-party
platform components (Prometheus, Loki, Kyverno, ArgoCD, Velero, External Secrets).
Helm and Kustomize solve overlapping but different problems.

## Decision
Use **Kustomize for our own application manifests** and **Helm for upstream
platform components**.

- App: a single `base/` with `overlays/{dev,staging,production}` patches. No
  templating language, transparent diffs, native `kubectl -k` / ArgoCD support.
- Platform: install via upstream Helm charts with environment-specific
  `values-*.yaml` (kube-prometheus-stack, loki, promtail, kyverno, velero,
  external-secrets).

## Consequences
- **Easier:** readable, reviewable app overlays; we don't reinvent complex charts
  that vendors maintain; values files keep env differences explicit.
- **Harder:** two mental models in one repo. Acceptable and conventional — the
  boundary (our code = Kustomize, their code = Helm) is easy to reason about.
