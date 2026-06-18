# SonarCloud — Code Quality & Security

Static analysis, coverage, and a Quality Gate enforced on every PR via the
**SonarCloud GitHub App** (free for public repos).

## Configuration

`sonar-project.properties`:

```properties
sonar.projectKey=mck21_devsecops-platform
sonar.organization=mck21
sonar.sources=app/backend/src
sonar.tests=app/backend/test
sonar.javascript.lcov.reportPaths=app/backend/coverage/lcov.info
sonar.exclusions=**/.github/**,**/infrastructure/**
sonar.qualitygate.wait=false
```

## How analysis runs

On the **free plan**, SonarCloud's **Automatic Analysis** runs via the GitHub App
and posts the `SonarCloud Code Analysis` check on PRs. A manual scanner job is
intentionally **not** used — it conflicts with Automatic Analysis. CI publishes
the Jest LCOV coverage report (`app/backend/coverage/lcov.info`) which SonarCloud
ingests for coverage metrics.

## Quality Gate

The gate blocks merges on: new bugs, new vulnerabilities, unreviewed **security
hotspots**, coverage on new code below threshold, and excessive duplication.
Security hotspot review is part of the Phase 6 security posture.

## SonarCloud's role across phases

| Phase | Role |
|-------|------|
| 4 — CI | SAST scan, coverage, Quality Gate on PRs |
| 6 — Security | Security Hotspots review, OWASP rules in the gate |
| 7 — Monitoring | (optional) Grafana panel pulling SonarCloud API for quality trends |

## Local

```bash
cd app/backend
bun run test:ci     # produces coverage/lcov.info
```

The badge in the README pulls live status from the SonarCloud API.
