#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-staging}"

CURRENT="$(grep 'ACTIVE_COLOR:' "$ROOT/k8s/overlays/staging/active-color.yaml" | awk '{print $2}')"
if [[ "$CURRENT" == "blue" ]]; then
  REVERT_TO="green"
else
  REVERT_TO="blue"
fi

python3 "$ROOT/scripts/traffic_switch.py" "$REVERT_TO"

echo "Rollback: reverted VirtualService and active-color to ${REVERT_TO}"
echo "Revert the GitOps image bump commit if the idle color image must be rolled back."

if command -v argocd >/dev/null 2>&1; then
  argocd app rollback feature-flags-staging || true
fi

kubectl rollout status "deployment/backend-${REVERT_TO}" -n "$NAMESPACE" --timeout=120s || true
