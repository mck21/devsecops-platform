# ADR-006: Feature Flag Service as the demo domain

## Status
Accepted

## Context
A DevSecOps platform needs a demo workload. It should make each infrastructure
decision feel *earned* rather than arbitrary (why a cache? why an HPA? why
overlays?), while staying small enough to not distract from the platform.

## Decision
Build a **Feature Flag Service** (manage toggles per environment; Redis-cached
reads; PostgreSQL audit log). Real-world equivalents: LaunchDarkly, Unleash,
Flipt.

## Consequences
- **Earned decisions:** flag reads happen on every client request → justifies the
  **Redis cache** and the **HPA**; per-environment toggles → justify **Kustomize
  overlays**; the audit log → justifies **PostgreSQL** persistence; rare writes /
  frequent reads → a clean cache-invalidation story.
- **Bounded scope:** five small NestJS modules (`flags`, `audit`, `health`,
  `cache`, `prisma`) keep app code from overshadowing the platform.
- **Harder:** none significant; the domain is intentionally simple.
