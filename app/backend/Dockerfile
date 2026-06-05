# ──────────────────────────────────────────
# Stage 1: deps
# ──────────────────────────────────────────
FROM oven/bun:1 AS deps

WORKDIR /app

COPY package.json bun.lockb* ./
COPY prisma ./prisma
RUN bun install --frozen-lockfile

# ──────────────────────────────────────────
# Stage 2: builder
# ──────────────────────────────────────────
FROM oven/bun:1 AS builder

WORKDIR /app

# Dummy URL for prisma generate at build time (runtime URL comes from K8s secret)
ARG DATABASE_URL=postgresql://build:build@localhost:5432/build
ENV DATABASE_URL=$DATABASE_URL

COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bun run build

# ──────────────────────────────────────────
# Stage 3: runner
# ──────────────────────────────────────────
FROM oven/bun:1-slim AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts
COPY package.json ./
COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh

EXPOSE 3000

CMD ["./docker-entrypoint.sh"]