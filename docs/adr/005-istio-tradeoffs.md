# ADR-005: Keep Istio despite its operational cost

## Status
Accepted

## Context
Istio adds real complexity: sidecar injection, TCP services needing `appProtocol`
+ DestinationRules, LimitRange tuning for the proxy, and higher resource use
(documented in [../../TROUBLESHOOTING.md](../../TROUBLESHOOTING.md)). A simpler
ingress-only setup would avoid these. But the platform relies on mesh features.

## Decision
**Keep Istio.** It provides the blue/green traffic switching via `VirtualService`
weights (core to the Phase 5 CD flow), consistent mesh metrics
(`istio_requests_total`) that power the SLOs independently of app code, and
distributed tracing via Jaeger.

## Consequences
- **Easier:** zero-downtime blue/green by shifting weights; uniform telemetry for
  SLOs/dashboards; mTLS-capable mesh.
- **Harder:** operational gotchas (TCP routing for postgres/redis, sidecar
  resource overhead, NetworkPolicy must allow Istiod/DNS). These are documented
  and templated, so the cost is paid once. For a tiny single-service app this is
  arguably over-engineered — accepted deliberately to demonstrate mesh skills.
