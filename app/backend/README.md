# Backend — Feature Flag Service

> **Agent note:** Phase 3 complete. All API endpoints, audit logging (create/toggle/delete), health checks (PostgreSQL + Redis), and Prometheus metrics are implemented. For project context and gotchas, see [AGENTS.md](../../AGENTS.md) and [STATUS.md](../../STATUS.md).

REST API built with NestJS to manage **feature flags** (environment-specific feature toggles). Data is persisted in **PostgreSQL** (via Prisma), read operations are cached in **Redis**, and an **audit endpoint** is available to inspect changes.

This document is intended for developers who are new to NestJS. It explains the project structure, framework concepts, and the end-to-end lifecycle of an HTTP request.

---

# NestJS Fundamentals

NestJS organizes code into layers using **Dependency Injection (DI)**. The main building blocks used in this project are:

| Concept                        | Purpose                                                           | Example in this repository            |
| ------------------------------ | ----------------------------------------------------------------- | ------------------------------------- |
| **Module** (`@Module`)         | Groups controllers, services, and related configuration           | `FlagsModule`                         |
| **Controller** (`@Controller`) | Handles HTTP requests, defines routes, delegates work to services | `FlagsController` → `POST /api/flags` |
| **Service** (`@Injectable`)    | Business logic, database/cache access                             | `FlagsService`                        |
| **DTO** (Data Transfer Object) | Defines and validates request bodies and query params             | `CreateFlagDto`                       |
| **Pipe**                       | Transforms or validates data before reaching a handler            | Global `ValidationPipe` in `main.ts`  |
| **Provider**                   | Injectable class managed by Nest's DI container                   | `PrismaService`, `FlagsService`       |

General flow:

```text
HTTP Request → Controller → Service → (Prisma / Redis) → Service → Controller → HTTP Response
```

Nest creates a **DI container**. When a controller requests a service through its constructor, Nest resolves and injects it automatically.

---

# Project Structure

```text
app/backend/
├── prisma/
│   └── schema.prisma          # Data models (Flag, AuditLog)
├── prisma.config.ts           # Database URL for Prisma CLI (migrate, generate)
├── src/
│   ├── main.ts                # Application bootstrap
│   ├── app.module.ts          # Root module
│   │
│   ├── flags/
│   │   ├── flags.module.ts
│   │   ├── flags.controller.ts
│   │   ├── flags.service.ts
│   │   └── dto/
│   │       ├── create-flag.dto.ts
│   │       └── toggle-flag.dto.ts
│   │
│   ├── audit/
│   │   ├── audit.module.ts
│   │   ├── audit.controller.ts
│   │   └── audit.service.ts
│   │
│   ├── prisma/
│   │   ├── prisma.module.ts
│   │   └── prisma.service.ts
│   │
│   ├── cache/
│   │   └── cache.module.ts
│   │
│   └── health/
│       └── health.controller.ts
│
├── test/                      # Jest e2e tests
├── package.json
├── tsconfig.json
└── nest-cli.json
```

## Files Outside `src/` (Nest Scaffold)

The repository still contains `app.controller.ts` and `app.service.ts` from the default NestJS template ("Hello World!"), but they are **not registered** in `AppModule`, so they do not expose any routes.

The actual application lives in the `flags`, `audit`, and `health` modules.

---

# Module Graph

```mermaid
flowchart TB
  subgraph bootstrap [Bootstrap]
    main["main.ts"]
    appMod["AppModule"]
    main --> appMod
  end

  subgraph global [Global Modules]
    config["ConfigModule\n(env vars)"]
    prisma["PrismaModule\n@Global"]
    cache["CacheConfigModule\nRedis global"]
  end

  subgraph domain [Domain]
    flags["FlagsModule"]
    audit["AuditModule"]
  end

  subgraph infra [Health]
    health["HealthController"]
    terminus["TerminusModule"]
  end

  appMod --> config
  appMod --> prisma
  appMod --> cache
  appMod --> flags
  appMod --> audit
  appMod --> terminus
  appMod --> health

  flags --> prisma
  flags --> cache
  audit --> prisma
```

| Module              | Global | Exports         | Used By                        |
| ------------------- | ------ | --------------- | ------------------------------ |
| `ConfigModule`      | Yes    | —               | `CacheConfigModule`            |
| `PrismaModule`      | Yes    | `PrismaService` | `FlagsService`, `AuditService` |
| `CacheConfigModule` | Yes    | `CACHE_MANAGER` | `FlagsService`                 |
| `FlagsModule`       | No     | `FlagsService`  | HTTP only                      |
| `AuditModule`       | No     | `AuditService`  | HTTP only                      |

Since `PrismaModule` and cache are global, services can inject `PrismaService` or `CACHE_MANAGER` without explicitly importing those modules.

---

# Bootstrap: `main.ts`

During startup:

1. `NestFactory.create(AppModule)` builds the module tree and resolves dependencies.
2. A global `ValidationPipe` is registered:

   * `whitelist`: strips unknown properties.
   * `forbidNonWhitelisted`: rejects requests with extra fields.
   * `transform`: converts JSON into DTO instances.
3. `enableCors()` allows cross-origin requests.
4. The application listens on port **3000**.

```typescript
const app = await NestFactory.create(AppModule);

app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
);

app.enableCors();

await app.listen(3000);
```

---

# Layer Overview

## `prisma/` — Database

### Schema (`prisma/schema.prisma`)

| Model      | Key Fields                                                      | Relationship        |
| ---------- | --------------------------------------------------------------- | ------------------- |
| `Flag`     | `key` (unique), `name`, `environments` (JSON)                   | Has many `AuditLog` |
| `AuditLog` | `flagKey`, `action`, `environment`, `previousValue`, `newValue` | Belongs to a `Flag` |

### `PrismaService`

Extends `PrismaClient` and uses `@prisma/adapter-pg` with the native `pg` pool.

Responsibilities:

* Connect on startup (`onModuleInit`)
* Disconnect on shutdown (`onModuleDestroy`)
* Expose typed delegates:

  * `this.prisma.flag`
  * `this.prisma.auditLog`

After modifying the schema:

```bash
bunx prisma generate
bunx prisma migrate dev
```

---

## `cache/` — Redis

`CacheConfigModule` registers Redis (`cache-manager-redis-yet`) asynchronously.

Configuration:

* Host from `REDIS_HOST`
* Port from `REDIS_PORT`
* Default TTL: 60 seconds

The `CACHE_MANAGER` token is available globally.

Currently only `FlagsService` uses caching.

---

## `flags/` — Feature Flags

| File                     | Responsibility                         |
| ------------------------ | -------------------------------------- |
| `flags.controller.ts`    | HTTP routes under `/api/flags`         |
| `flags.service.ts`       | CRUD operations, toggle logic, caching |
| `dto/create-flag.dto.ts` | Creation validation                    |
| `dto/toggle-flag.dto.ts` | Toggle validation                      |

Supported environments:

* `dev`
* `staging`
* `production`

Each environment stores a boolean value.

---

## `audit/` — Audit Logs

| File                  | Responsibility          |
| --------------------- | ----------------------- |
| `audit.controller.ts` | `GET /api/audit`        |
| `audit.service.ts`    | `findAll()` and `log()` |

> **Note:** `AuditService.log()` exists but is not currently invoked by `FlagsService.toggle()`. Flag changes are not automatically recorded yet.

---

## `health/` — Service Health

`HealthController` uses `@nestjs/terminus`.

Endpoint:

```http
GET /health
```

Currently it executes:

```typescript
health.check([])
```

This only returns a basic `ok` status and does not probe PostgreSQL or Redis.

---

# API Endpoints

| Method | Route                    | Description                      |
| ------ | ------------------------ | -------------------------------- |
| GET    | `/health`                | Health check                     |
| POST   | `/api/flags`             | Create a flag                    |
| GET    | `/api/flags`             | List flags (`?env=dev` optional) |
| GET    | `/api/flags/:key`        | Get a flag (Redis cached)        |
| PATCH  | `/api/flags/:key/toggle` | Toggle an environment value      |
| DELETE | `/api/flags/:key`        | Delete a flag                    |
| GET    | `/api/audit`             | Latest 100 audit logs            |

---

## Example Request Bodies

### Create Flag

`POST /api/flags`

```json
{
  "key": "new-checkout",
  "name": "New Checkout Flow",
  "description": "New checkout rollout",
  "environments": {
    "dev": true,
    "staging": false,
    "production": false
  }
}
```

### Toggle Flag

`PATCH /api/flags/new-checkout/toggle`

```json
{
  "environment": "staging"
}
```

---

# Request → Response Flow

## 1. `GET /health`

```text
Client → HealthController → HealthCheckService → Response
```

No database or cache interaction.

---

## 2. `POST /api/flags`

```text
Request
  ↓
ValidationPipe
  ↓
FlagsController.create()
  ↓
FlagsService.create()
  ↓
Prisma (PostgreSQL)
  ↓
Response
```

Detailed steps:

1. Express receives the request.
2. ValidationPipe validates the payload against `CreateFlagDto`.
3. Controller receives a typed DTO.
4. Service calls `prisma.flag.create()`.
5. Database record is returned as JSON.

---

## 3. `GET /api/flags/:key`

```text
Request
  ↓
FlagsController
  ↓
FlagsService
  ↓
Redis cache?
  ├─ Hit → Return cached value
  └─ Miss → PostgreSQL → Cache → Return
```

If the flag does not exist:

```http
404 Not Found
```

---

## 4. `PATCH /api/flags/:key/toggle`

```text
Request
  ↓
ValidationPipe
  ↓
Controller
  ↓
Service
  ↓
Find Flag
  ↓
Invert Environment Value
  ↓
Update PostgreSQL
  ↓
Invalidate Redis Cache
  ↓
Response
```

Response includes:

```json
{
  "updated": true,
  "previousValue": false,
  "newValue": true
}
```

---

## 5. `GET /api/audit?env=staging`

```text
Request
  ↓
AuditController
  ↓
AuditService
  ↓
Prisma
  ↓
auditLog.findMany(...)
  ↓
Response
```

Returns up to 100 entries ordered by newest first.

---

# Environment Variables

| Variable       | Required | Purpose               |
| -------------- | -------- | --------------------- |
| `DATABASE_URL` | Yes      | PostgreSQL connection |
| `REDIS_HOST`   | No       | Redis hostname        |
| `REDIS_PORT`   | No       | Redis port            |

Example:

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/featureflags
REDIS_HOST=localhost
REDIS_PORT=6379
```

`ConfigModule.forRoot()` loads values from a `.env` file in the working directory.

---

# Bun Scripts

| Script                    | Description                             |
| ------------------------- | --------------------------------------- |
| `bun run start:dev`       | Development with hot reload             |
| `bun run build`           | Generate Prisma client + build Nest app |
| `bun run start:prod`      | Run `dist/main.js`                      |
| `bun run prisma:generate` | Regenerate Prisma client                |
| `bun run test`            | Unit tests                              |
| `bun run test:e2e`        | End-to-end tests                        |
| `bun run lint`            | ESLint                                  |

---

# Getting Started

```bash
cd app/backend

bun install

# First time only
bunx prisma migrate dev

# Start development server
bun run start:dev
```

Verify:

```bash
curl http://localhost:3000/health
curl http://localhost:3000/api/flags
```

---

# Key Dependencies

| Package                                             | Purpose                   |
| --------------------------------------------------- | ------------------------- |
| `@nestjs/common`, `@nestjs/core`                    | NestJS framework          |
| `@nestjs/config`                                    | Environment variables     |
| `@nestjs/cache-manager` + `cache-manager-redis-yet` | Redis caching             |
| `@nestjs/terminus`                                  | Health checks             |
| `@prisma/client`, `@prisma/adapter-pg`, `pg`        | PostgreSQL ORM and driver |
| `class-validator`, `class-transformer`              | DTO validation            |

---

# Mental Map for Navigating the Codebase

When debugging a request:

1. **`main.ts`** → Check global pipes and middleware.
2. **`app.module.ts`** → Verify active modules.
3. **Controller** → Find the HTTP route.
4. **Service** → Inspect business logic and dependencies.
5. **`prisma/schema.prisma`** → Understand the data model.

Typical NestJS workflow for a new feature:

```text
Generate Module
    ↓
Generate Controller
    ↓
Generate Service
    ↓
Create DTOs
    ↓
Register Module
```

Using the Nest CLI through Bun:

```bash
bunx nest g module features
bunx nest g controller features
bunx nest g service features
```

---

# Current State & Potential Improvements

* Connect `AuditService.log()` inside `FlagsService.toggle()`.
* Add PostgreSQL and Redis probes to `/health`.
* Use `process.env.PORT` instead of a hardcoded port.
* Remove or register the unused `AppController` and `AppService`.
* Update `test/app.e2e-spec.ts` to match the actual API routes.
* Add authentication - who made the change? for audit logs
