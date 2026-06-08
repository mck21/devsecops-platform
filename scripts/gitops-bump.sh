#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHA_TAG="${1:?Usage: gitops-bump.sh <sha-tag>}"

python3 "$ROOT/scripts/gitops_bump.py" "$SHA_TAG"
