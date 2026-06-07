# Troubleshooting Guide

Runbook for deployment issues encountered during Phase 3 (Minikube + Istio + NestJS + Prisma v7). Check this before assuming an application bug.

**Related docs:** [AGENTS.md](AGENTS.md) · [k8s/README.md](k8s/README.md) · [PLAN.md § Deployment Gotchas](PLAN.md)

---

## Quick Symptom Index

| Symptom / Error | Category | Jump to |
|-----------------|----------|---------|
| `The datasource.url property is required in your Prisma config file` | Prisma v7 | [§ Prisma v7](#prisma-v7) |
| `P1001: Can't reach database server` | Istio + TCP | [§ Istio and TCP services](#istio-and-tcp-services-postgresql-redis) |
| `Socket closed unexpectedly` (Redis) | Istio + TCP | [§ Istio and TCP services](#istio-and-tcp-services-postgresql-redis) |
| `FailedCreate: minimum cpu usage per Container is 50m, but request is 10m` | LimitRange | [§ LimitRange vs Istio sidecar](#limitrange-vs-istio-sidecar) |
| Pod stuck in `Init` or sidecar not injected | LimitRange | [§ LimitRange vs Istio sidecar](#limitrange-vs-istio-sidecar) |
| `exceeded quota: namespace-quota, limits.cpu` | ResourceQuota | [§ ResourceQuota during rollouts](#resourcequota-during-rollouts) |
| Code changes not reflected after rebuild | Minikube images | [§ Minikube image caching](#minikube-image-caching) |
| `Cannot find module` / app exits immediately on start | NestJS build | [§ NestJS build output path](#nestjs-build-output-path) |
| `CrashLoopBackOff` on backend startup | Prisma migrate | [§ Prisma migrate on startup](#prisma-migrate-on-startup) |
| `/health` returns 503 | Dependencies | [§ Health check failures](#health-check-failures) |
| Ingress not reachable | Minikube networking | [§ Ingress and LoadBalancer](#ingress-and-loadbalancer-minikube) |

---

## Diagnostic Commands

Run these first when a deploy fails:

```bash
# Pod status and restarts
kubectl get pods -n dev
kubectl describe pod -l app=backend -n dev

# Backend logs (app + istio-proxy)
kubectl logs -l app=backend -n dev -c backend --tail=100
kubectl logs -l app=backend -n dev -c istio-proxy --tail=50

# Verify Istio sidecar injection
kubectl get pod -l app=backend -n dev -o jsonpath='{.items[0].spec.containers[*].name}'
# Expected: backend istio-proxy

# Test TCP connectivity from a debug pod (without sidecar)
kubectl run -it --rm debug --image=busybox -n dev --restart=Never -- \
  nc -zv postgres 5432

# HPA and quota
kubectl get hpa -n dev
kubectl describe resourcequota -n dev

# Applied manifests
kubectl apply -k k8s/overlays/dev --dry-run=client
```

---

## Prisma v7

Prisma 7 moved database URL configuration out of `schema.prisma` into `prisma.config.ts`. This affects local dev, Docker builds, and Kubernetes deploys.

### Error: `The datasource.url property is required in your Prisma config file`

**Cause:** `prisma.config.ts` is missing from the container or `DATABASE_URL` is not set at runtime.

**Fix:**

1. Ensure `prisma.config.ts` exists and uses `env()` from `prisma/config`:

```typescript
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: { path: "prisma/migrations" },
  datasource: { url: env("DATABASE_URL") },
});
```

2. Docker runner stage must copy the config file — see [`app/backend/Dockerfile`](app/backend/Dockerfile):

```dockerfile
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts
```

3. Kubernetes must inject `DATABASE_URL` via Secret — see [`k8s/base/deployment.yaml`](k8s/base/deployment.yaml) and [`k8s/base/secret.yaml`](k8s/base/secret.yaml).

**Do not** use bare `process.env.DATABASE_URL` in `prisma.config.ts` — Prisma v7 expects `env('DATABASE_URL')`.

### Error: `prisma generate` fails during Docker build

**Cause:** Build stage runs `prisma generate` without a `DATABASE_URL`.

**Fix:** Provide a dummy URL in the builder stage:

```dockerfile
ARG DATABASE_URL=postgresql://build:build@localhost:5432/build
ENV DATABASE_URL=$DATABASE_URL
```

See [`app/backend/Dockerfile`](app/backend/Dockerfile) lines 19–21.

### Prisma migrate on startup

The entrypoint runs `prisma migrate deploy` before starting the app. With Istio, the database may not be reachable until Envoy is ready.

**Symptoms:** Backend pod in `CrashLoopBackOff`; logs show repeated `Waiting for database... attempt N/30`.

**Fixes (apply all that apply):**

1. Set `holdApplicationUntilProxyStarts: true` on the backend pod — already in [`k8s/base/deployment.yaml`](k8s/base/deployment.yaml):

```yaml
annotations:
  proxy.istio.io/config: |
    holdApplicationUntilProxyStarts: true
```

2. Fix Istio TCP routing for postgres — see [Istio and TCP services](#istio-and-tcp-services-postgresql-redis).

3. The entrypoint retries migrate up to 30 times — see [`app/backend/docker-entrypoint.sh`](app/backend/docker-entrypoint.sh). If all retries fail, check postgres pod logs:

```bash
kubectl logs -l app=postgres -n dev
```

---

## NestJS build output path

### Error: `Cannot find module` or `dist/main.js` not found

**Cause:** `nest build` emits `dist/src/main.js`, not `dist/main.js`.

**Fix:** Ensure all start commands reference the correct path:

| File | Correct command |
|------|-----------------|
| [`app/backend/package.json`](app/backend/package.json) | `"start:prod": "bun dist/src/main.js"` |
| [`app/backend/docker-entrypoint.sh`](app/backend/docker-entrypoint.sh) | `exec bun dist/src/main.js` |

---

## Minikube image caching

### Symptom: Code changes not reflected after `docker build` + redeploy

**Cause:** Dev overlay sets `imagePullPolicy: Never` with tag `latest`. Kubernetes reuses the image already cached on the Minikube node. `minikube image load` does not replace an in-use image.

**Fix:**

```bash
kubectl scale deployment/backend -n dev --replicas=0
minikube ssh "docker rmi -f backend:latest"
docker build -t backend:latest ./app/backend
minikube image load backend:latest
kubectl scale deployment/backend -n dev --replicas=1
kubectl rollout status deployment/backend -n dev
```

**Prevention:** Use versioned tags (e.g. `backend:sha-abc123`) instead of `latest`. CI (Phase 4) pushes `sha-<commit>` tags to ECR on every green build.

**Related file:** [`k8s/overlays/dev/patch-deployment.yaml`](k8s/overlays/dev/patch-deployment.yaml) (`imagePullPolicy: Never`).

---

## Istio and TCP services (PostgreSQL, Redis)

The most common class of deploy failures when Istio sidecar injection is enabled on the `dev` namespace.

### Error: `P1001: Can't reach database server at postgres:5432`

**Cause:** Istio treats unnamed Service ports as **HTTP**. Envoy intercepts PostgreSQL/Redis TCP traffic and the connection fails — even though raw TCP (`nc`) from a pod without a sidecar works.

**Symptoms:**

- Prisma `P1001` in backend logs
- Redis: `Socket closed unexpectedly`
- Health check fails on PostgreSQL or Redis

**Fix (three parts — all required):**

#### 1. Name ports with `tcp-` prefix and set `appProtocol: tcp`

On Kubernetes Services for postgres and redis:

```yaml
ports:
  - name: tcp-postgres   # must start with tcp-, http-, or grpc-
    port: 5432
    targetPort: 5432
    appProtocol: tcp
```

See [`k8s/base/postgres.yaml`](k8s/base/postgres.yaml) and [`k8s/base/redis.yaml`](k8s/base/redis.yaml).

**After changing Services, restart affected pods** so Envoy picks up the new protocol:

```bash
kubectl rollout restart deployment/postgres deployment/redis deployment/backend -n dev
```

#### 2. Add DestinationRule with TLS disabled

`appProtocol: tcp` alone is not always sufficient. Add DestinationRules:

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: postgres
spec:
  host: postgres
  trafficPolicy:
    tls:
      mode: DISABLE
```

See [`k8s/base/destinationrules-tcp.yaml`](k8s/base/destinationrules-tcp.yaml). Ensure it is listed in [`k8s/base/kustomization.yaml`](k8s/base/kustomization.yaml).

#### 3. Wait for Envoy before app connects

Add to backend Deployment pod template:

```yaml
annotations:
  proxy.istio.io/config: |
    holdApplicationUntilProxyStarts: true
```

Without this, Prisma may attempt `migrate deploy` before the Istio proxy is ready.

### Verify Istio injection is enabled

```bash
kubectl get namespace dev --show-labels
# Expected label: istio-injection=enabled
```

If missing:

```bash
kubectl label namespace dev istio-injection=enabled
kubectl rollout restart deployment -n dev
```

---

## LimitRange vs Istio sidecar

### Error: `FailedCreate: minimum cpu usage per Container is 50m, but request is 10m`

**Cause:** Namespace `LimitRange` sets `min.cpu` higher than what the Istio sidecar requests. The sidecar proxy defaults to `10m` CPU / `40Mi` memory. If `LimitRange` `min` is e.g. `50m`, the sidecar cannot be injected and pod creation fails.

**Symptoms:**

- Pod stuck in `Pending` with FailedCreate events
- Only one container in pod (no `istio-proxy`)
- Event: `minimum cpu usage per Container is X, but request is 10m`

**Fix:** Set LimitRange minimums compatible with Istio sidecar:

```yaml
min:
  cpu: 10m
  memory: 40Mi
```

See [`k8s/base/limitrange.yaml`](k8s/base/limitrange.yaml).

**Alternative:** Annotate pods with explicit sidecar resource requests (Istio 1.30+), but adjusting LimitRange is simpler for this project.

---

## ResourceQuota during rollouts

### Error: `exceeded quota: namespace-quota, limits.cpu`

**Cause:** With Istio sidecars, each pod consumes roughly `2200m` CPU in limits (app container + istio-proxy). During a rolling update, old and new pods coexist temporarily — doubling pod count. A tight quota (e.g. `limits.cpu: "8"`) causes new pods to fail creation.

**Symptoms:**

- `FailedCreate` events citing `exceeded quota`
- Rollout stuck; new ReplicaSet pods never start

**Fix:** Dev overlay increases quota to `limits.cpu: "16"`:

See [`k8s/overlays/dev/patch-resourcequota.yaml`](k8s/overlays/dev/patch-resourcequota.yaml).

```bash
kubectl describe resourcequota namespace-quota -n dev
```

**Note:** Staging/production overlays may need similar adjustments when deployed with Istio sidecars.

---

## Secrets and configuration

### Error: Backend pod starts but crashes on Prisma connect

**Cause:** `backend-secrets` Secret not applied or `DATABASE_URL` points to wrong host.

**Fix:**

1. Apply the secret template locally (never commit real production values):

```bash
kubectl apply -f k8s/base/secret.yaml -n dev
```

2. Verify the URL matches in-cluster service names:

```
postgresql://postgres:postgres@postgres:5432/featureflags
```

Host must be `postgres` (Kubernetes Service name), not `localhost`.

3. Confirm Secret is mounted:

```bash
kubectl get secret backend-secrets -n dev
kubectl describe deployment backend -n dev | grep -A5 DATABASE_URL
```

---

## Health check failures

### Symptom: `/health` returns 503 or readiness probe fails

**Cause:** Terminus health check validates both PostgreSQL and Redis. Either dependency unreachable triggers failure.

**Diagnosis:**

```bash
kubectl port-forward svc/backend -n dev 3000:80
curl -v http://localhost:3000/health
```

Check which indicator fails in the JSON response, then trace to [Istio TCP](#istio-and-tcp-services-postgresql-redis) or [Secrets](#secrets-and-configuration).

**Probe timing:** Backend has `initialDelaySeconds: 10` (readiness) and `15` (liveness) to allow Prisma migrate + Istio startup. If migrate takes longer, increase delays in [`k8s/base/deployment.yaml`](k8s/base/deployment.yaml).

---

## Ingress and LoadBalancer (Minikube)

### Symptom: Ingress URL not reachable

**Cause:** Minikube LoadBalancer services require `minikube tunnel` running in a separate terminal.

**Fix:**

1. Add to `/etc/hosts`:

```
127.0.0.1 flags.dev.local
```

2. Start tunnel:

```bash
minikube tunnel
```

3. Verify Ingress:

```bash
kubectl get ingress -n dev
curl http://flags.dev.local/health
```

**Alternative:** Skip Ingress and use port-forward:

```bash
kubectl port-forward svc/backend -n dev 3000:80
```

---

## HPA not scaling

### Symptom: `kubectl get hpa -n dev` shows `<unknown>` targets

**Cause:** Metrics Server not installed or not ready on Minikube.

**Fix:**

```bash
minikube addons enable metrics-server
kubectl get apiservice v1beta1.metrics.k8s.io
```

Dev overlay sets `minReplicas: 1` — see [`k8s/overlays/dev/patch-hpa.yaml`](k8s/overlays/dev/patch-hpa.yaml). Base HPA allows up to 10 replicas at 70% CPU / 80% memory — see [`k8s/base/hpa.yaml`](k8s/base/hpa.yaml).

---

## Docker Compose (local)

Local stack does not use Istio. Most K8s/Istio issues do not apply.

| Symptom | Fix |
|---------|-----|
| Backend starts before postgres ready | `depends_on` with healthchecks in [`docker-compose.yml`](docker-compose.yml) |
| Port 5432 already in use | Stop local postgres or change port mapping |
| Prisma migrate fails locally | Ensure `.env` has valid `DATABASE_URL`; run `bunx prisma migrate deploy` from `app/backend/` |

---

## Related Files

| Topic | File |
|-------|------|
| Prisma config | [`app/backend/prisma.config.ts`](app/backend/prisma.config.ts) |
| Docker build | [`app/backend/Dockerfile`](app/backend/Dockerfile) |
| Entrypoint / migrate | [`app/backend/docker-entrypoint.sh`](app/backend/docker-entrypoint.sh) |
| Backend deployment | [`k8s/base/deployment.yaml`](k8s/base/deployment.yaml) |
| Dev image policy | [`k8s/overlays/dev/patch-deployment.yaml`](k8s/overlays/dev/patch-deployment.yaml) |
| Postgres / Redis services | [`k8s/base/postgres.yaml`](k8s/base/postgres.yaml), [`k8s/base/redis.yaml`](k8s/base/redis.yaml) |
| Istio TCP DestinationRules | [`k8s/base/destinationrules-tcp.yaml`](k8s/base/destinationrules-tcp.yaml) |
| LimitRange | [`k8s/base/limitrange.yaml`](k8s/base/limitrange.yaml) |
| Dev ResourceQuota patch | [`k8s/overlays/dev/patch-resourcequota.yaml`](k8s/overlays/dev/patch-resourcequota.yaml) |
| Secret template | [`k8s/base/secret.yaml`](k8s/base/secret.yaml) |
| Istio install notes | [`k8s/istio/istio-notes.md`](k8s/istio/istio-notes.md) |

---

## Adding New Issues

When a new deploy issue is discovered:

1. Document the **symptom**, **cause**, and **fix** in this file
2. Add a row to the [Quick Symptom Index](#quick-symptom-index)
3. Update [AGENTS.md](AGENTS.md) if it affects agent phase boundaries
4. Capture evidence in `images/phase-N/` if relevant
