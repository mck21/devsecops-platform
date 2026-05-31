# Istio Installation

## Dev (Minikube)
Installed via istioctl with demo profile:
istioctl install --set profile=demo -y

Istio version used: 1.30.0

Addons installed:
- Kiali (service mesh topology)
- Jaeger (distributed tracing)
- Prometheus (metrics, Istio-scoped)

Access dashboards:
istioctl dashboard kiali
istioctl dashboard jaeger

Sidecar injection enabled on namespaces:
- dev

## Staging/Production (EKS)
Installed via istioctl with production profile in Phase 5.