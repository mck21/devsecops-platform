# ADR-001: ArgoCD over Flux CD

## Status
Accepted

## Context
GitOps needs a controller that reconciles cluster state from Git. The two mature
CNCF options are ArgoCD and Flux CD. We want clear visibility of sync/health for a
portfolio project, multi-environment app management, and a gentle learning curve.

## Decision
Use **ArgoCD**. It ships a first-class UI showing per-Application sync and health
status, the `Application` CRD maps cleanly to our per-overlay environments, and it
integrates well with the blue/green traffic-switch flow and sync waves we use.

## Consequences
- **Easier:** observing drift/sync state visually (great for screenshots and
  demos), modelling dev/staging/production as separate Applications, manual
  sync/rollback from the UI or CLI.
- **Harder / cost:** ArgoCD is a heavier install than Flux and is less "pure
  GitOps" for image automation (we drive image bumps from CI rather than an
  in-cluster image automation controller). Acceptable: the CD pipeline already
  owns tag bumping and blue/green switching.
