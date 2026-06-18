#!/usr/bin/env bash
# Resilience drill helper — inject a failure and observe recovery.
# Usage: scripts/resilience-test.sh <scenario> [namespace]
#   scenarios: pod-crash | bad-deploy | cpu-stress | help
# Defaults to namespace "dev". Read-only on the cluster except the chosen action.
set -euo pipefail

SCENARIO="${1:-help}"
NS="${2:-dev}"

usage() {
  cat <<'EOF'
Resilience drill helper
  pod-crash   Delete a backend pod; expect auto-restart, no downtime
  bad-deploy  Set an invalid image; expect probes to fail (roll back via GitOps/CD)
  cpu-stress  Print the k6 command that drives HPA scale-out
EOF
}

case "$SCENARIO" in
  pod-crash)
    echo "[*] Pods before:"; kubectl get pods -n "$NS" -l app=backend
    POD="$(kubectl get pods -n "$NS" -l app=backend -o jsonpath='{.items[0].metadata.name}')"
    echo "[*] Deleting pod $POD ..."
    kubectl delete pod "$POD" -n "$NS"
    echo "[*] Watch recovery (Ctrl-C to stop):"
    kubectl get pods -n "$NS" -l app=backend -w
    ;;
  bad-deploy)
    DEPLOY="${3:-backend}"
    echo "[*] Setting invalid image on deployment/$DEPLOY in $NS ..."
    kubectl set image "deployment/$DEPLOY" backend=backend:does-not-exist -n "$NS"
    echo "[*] Watch rollout fail (probes/imagepull). Roll back with:"
    echo "    kubectl rollout undo deployment/$DEPLOY -n $NS"
    kubectl rollout status "deployment/$DEPLOY" -n "$NS" --timeout=90s || true
    ;;
  cpu-stress)
    echo "[*] In one shell: kubectl get hpa -n $NS -w"
    echo "[*] In another:   BASE_URL=http://localhost:3000 k6 run tests/k6/stress-hpa.js"
    ;;
  help|*)
    usage
    ;;
esac
