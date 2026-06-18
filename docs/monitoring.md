# Monitoring & Observability

The full operational guide (install order, values, dashboards, access) lives in
[../monitoring/README.md](../monitoring/README.md). This page is the conceptual
overview.

## Three pillars

| Pillar | Tool | Notes |
|--------|------|-------|
| Metrics | Prometheus (kube-prometheus-stack) | app `/metrics`, Istio mesh, node + kube-state |
| Logs | Loki + Promtail | pino JSON logs; `req_id` / `trace_id` labels for correlation |
| Traces | Jaeger (via Istio) | distributed traces across the mesh |
| Dashboards/alerts | Grafana + Alertmanager | custom + community dashboards |

## Metric sources

- **Application:** `prom-client` / `@willsoto/nestjs-prometheus` exposes default
  process metrics plus app counters (e.g. cache hit/miss) at `GET /metrics`,
  scraped via `ServiceMonitor/backend`.
- **Mesh:** Istio emits `istio_requests_total` and
  `istio_request_duration_milliseconds_bucket` — the basis for SLOs (consistent
  across dev and EKS, independent of app code).
- **Cluster:** node-exporter + kube-state-metrics (bundled).

## Dashboards

Custom: **Feature Flag Service** (`feature-flags-app`) and **SLO — Error Budget**
(`slo-error-budget`), provisioned as `grafana_dashboard` ConfigMaps. Community:
Kubernetes (7249), Istio Mesh (7639), Node Exporter (1860).

## SLOs & alerting

SLIs/SLOs, error-budget policy and multi-window burn-rate alerts:
[sre.md](sre.md). Rules: [../monitoring/prometheus/prometheusrules.yaml](../monitoring/prometheus/prometheusrules.yaml).

## Logging correlation

pino emits structured JSON with a per-request `req.id`. Promtail promotes
`level` / `req_id` / `trace_id` so a request can be followed across logs (Loki)
and traces (Jaeger) from a single Grafana view.
