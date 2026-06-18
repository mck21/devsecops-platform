# k6 Load & Resilience Tests (Phase 8)

Load tests for the Feature Flag Service, used to validate SLOs and trigger HPA
scale-out during resilience drills.

## Install k6

```bash
brew install k6            # macOS
# or: docker run --rm -i grafana/k6 run - < tests/k6/load-flags-read.js
```

## Tests

| Script | Purpose | Pass criteria |
|--------|---------|---------------|
| `load-flags-read.js` | Steady 200 rps on the cache-hot read path | P95 < 300ms, errors < 0.1% (thresholds enforced) |
| `stress-hpa.js` | Ramp load to push CPU past 70% | HPA scales replicas up, then back down |

## Run against dev (Minikube)

```bash
kubectl port-forward svc/backend -n dev 3000:80 &
# seed a flag first if needed:
curl -X POST localhost:3000/api/flags -H 'content-type: application/json' \
  -d '{"key":"checkout-v2","description":"demo","environments":{"production":true}}'

BASE_URL=http://localhost:3000 FLAG_KEY=checkout-v2 k6 run tests/k6/load-flags-read.js
```

## Run against staging (EKS)

```bash
BASE_URL=https://flags.staging.example.com k6 run tests/k6/load-flags-read.js
```

## Observe HPA during stress

```bash
kubectl get hpa -n dev -w        # or -n staging
BASE_URL=http://localhost:3000 k6 run tests/k6/stress-hpa.js
```

Scenarios and expected outcomes are tracked in
[../../docs/resilience-testing.md](../../docs/resilience-testing.md).
