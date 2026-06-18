# ADR-007: Staging-first CD; production kept off as a Git mirror

## Status
Accepted

## Context
This is a portfolio project with a real AWS bill. Running staging **and**
production EKS clusters doubles cost and the failure surface while building the
pipeline, without adding much demonstrative value — the CD mechanics are identical
per environment.

## Decision
Make **staging** the only environment with a live runtime and automatic CD.
**Production** is kept fully in Git as a mirror of staging (Kustomize overlays,
Terraform, ArgoCD Application) but its runtime stays **off**. Enabling it later is
a documented, undecided step ([../cd-production-promotion.md](../cd-production-promotion.md)),
not a committed phase. Dev stays manual on Minikube.

## Consequences
- **Easier:** lower cost (~one EKS instead of two), smaller blast radius,
  faster iteration; the multi-environment IaC/manifest design is still fully
  demonstrated in Git.
- **Harder:** production manifests must be kept aligned with staging in every PR
  (a review checklist item); "production" is not provably running. Accepted — the
  promotion path is documented and the mirror is validated by `kubectl kustomize`.
