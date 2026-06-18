# ADR-004: GitHub Actions over Jenkins

## Status
Accepted

## Context
CI/CD needs an automation engine. Jenkins is powerful but self-hosted (a server to
patch, secure, and scale). The repo already lives on GitHub.

## Decision
Use **GitHub Actions**. It is fully managed, co-located with the code, has a large
marketplace, supports **OIDC federation to AWS** (no long-lived keys), and pins
actions by commit SHA for supply-chain safety.

## Consequences
- **Easier:** no CI server to operate; OIDC removes static AWS credentials;
  native PR checks and Sonar/Cosign integrations; `workflow_run` chaining for
  CI→CD.
- **Harder:** vendor lock-in to GitHub; less flexible than Jenkins for exotic
  agents. Acceptable for this project's scope and the security benefit of OIDC.
