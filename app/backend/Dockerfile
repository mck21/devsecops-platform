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

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build NestJS (outputs to dist/)
RUN bun run build

# ──────────────────────────────────────────
# Stage 3: runner (production image)
# ──────────────────────────────────────────
FROM oven/bun:1-slim AS runner

WORKDIR /app

ENV NODE_ENV=production

# Only copy what's needed to run
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY package.json ./

EXPOSE 3000

# Run migrations then start
CMD ["sh", "-c", "bunx prisma migrate deploy && bun dist/main.js"]