# Monitoring & Observability (Phase 7)

Prometheus + Grafana + Loki + Promtail, plus app `/metrics` scraping, SLO rules,
and curated dashboards. Works on Minikube (dev) and EKS (staging/production).

## Stack

| Component | Source | Dev | EKS |
|-----------|--------|-----|-----|
| Prometheus + Alertmanager + Grafana | `kube-prometheus-stack` (Helm) | 1 replica, ephemeral | HA, gp3 PVCs |
| Loki | `grafana/loki` (Helm) | SingleBinary, filesystem | SimpleScalable, S3 |
| Promtail | `grafana/promtail` (Helm) | DaemonSet | DaemonSet |
| Jaeger | via Istio addon (Phase 2) | demo | production |

## Install order

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 1. Metrics + dashboards (pick the right values file)
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f monitoring/prometheus/values-eks.yaml      # or values-dev.yaml

# 2. Logs
helm install loki grafana/loki -n monitoring -f monitoring/loki/values-eks.yaml      # or values-dev.yaml
helm install promtail grafana/promtail -n monitoring -f monitoring/promtail/values.yaml

# 3. App ServiceMonitor + SLO rules + custom dashboards
kubectl apply -k monitoring
```

## What's scraped

- **App metrics:** `ServiceMonitor/backend` scrapes `/metrics` (port `http`) in
  `dev`, `staging`, `production`.
- **Mesh metrics:** Istio emits `istio_requests_total` /
  `istio_request_duration_milliseconds_bucket` — the basis for SLOs.
- **Cluster metrics:** node-exporter + kube-state-metrics (bundled).

## Dashboards

| Dashboard | Source | UID |
|-----------|--------|-----|
| Feature Flag Service | custom (`grafana/dashboards/app-feature-flags.json`) | `feature-flags-app` |
| SLO — Error Budget | custom (`grafana/dashboards/slo-error-budget.json`) | `slo-error-budget` |
| Kubernetes Cluster | community gnetId 7249 | — |
| Istio Mesh | community gnetId 7639 | — |
| Node Exporter | community gnetId 1860 | — |

Custom dashboards are provisioned as `grafana_dashboard`-labelled ConfigMaps and
auto-imported by the Grafana sidecar.

## SLOs & alerts

SLIs/SLOs and the error-budget policy live in [../docs/sre.md](../docs/sre.md).
Alerting + multi-window burn-rate rules are in
[prometheus/prometheusrules.yaml](prometheus/prometheusrules.yaml).

## Access (dev)

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3001:80
# http://localhost:3001  (admin / admin)
```
