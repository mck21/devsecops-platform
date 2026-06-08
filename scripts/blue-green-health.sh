#!/usr/bin/env bash
set -euo pipefail

COLOR="${1:?Usage: blue-green-health.sh <blue|green> [namespace]}"
NAMESPACE="${2:-staging}"
DEPLOYMENT="backend-${COLOR}"
TIMEOUT="${TIMEOUT:-300s}"

echo "Waiting for deployment/${DEPLOYMENT} rollout in namespace ${NAMESPACE}..."
kubectl rollout status "deployment/${DEPLOYMENT}" -n "$NAMESPACE" --timeout="$TIMEOUT"

POD="$(kubectl get pods -n "$NAMESPACE" -l "app=backend,version=${COLOR}" \
  -o jsonpath='{.items[0].metadata.name}')"

if [[ -z "$POD" ]]; then
  echo "No pod found for color ${COLOR}" >&2
  exit 1
fi

echo "Checking /health on pod ${POD}..."
for _ in $(seq 1 30); do
  if kubectl exec -n "$NAMESPACE" "$POD" -c backend -- \
    wget -qO- http://127.0.0.1:3000/health >/dev/null 2>&1; then
    echo "Health check passed for ${COLOR}"
    exit 0
  fi
  sleep 5
done

echo "Health check failed for ${COLOR}" >&2
exit 1
