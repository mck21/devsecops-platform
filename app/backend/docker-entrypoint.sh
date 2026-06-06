#!/bin/sh
set -e

# Wait for postgres (Istio sidecar + DB startup)
for i in $(seq 1 30); do
  if bunx prisma migrate deploy 2>/dev/null; then
    break
  fi
  echo "Waiting for database... attempt $i/30"
  sleep 2
done

bunx prisma migrate deploy
exec bun dist/src/main.js
