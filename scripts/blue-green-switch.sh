#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_COLOR="${1:?Usage: blue-green-switch.sh <blue|green>}"

python3 "$ROOT/scripts/traffic_switch.py" "$TARGET_COLOR"
