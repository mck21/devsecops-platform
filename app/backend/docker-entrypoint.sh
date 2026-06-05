#!/bin/sh
set -e

bunx prisma migrate deploy
exec bun dist/src/main.js
