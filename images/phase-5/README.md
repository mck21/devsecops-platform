# Phase 5 — CD & GitOps evidence

Evidence captured from the live staging EKS pipeline before the AWS environment
was decommissioned. This set is **final** — no cluster access remains, so no
further screenshots will be added.

## Evidence

| File | Content |
|------|---------|
| `01-argocd-sync.png` | ArgoCD UI — `feature-flags-staging` Synced + Healthy on EKS |
| `03-blue-green-virtualservice.png` | Istio VirtualService showing the blue/green traffic split in staging |

Additional CD evidence lives in Git history itself: the GitOps bump commits on
`main` (e.g. `chore(staging): pin backend to sha-5137706`) and the green CI/CD
runs in the repository's Actions tab.

## Notes

- Dev (Minikube) CD is manual — no runtime evidence required.
- Production exists in Git as a staging mirror only — runtime was never lifted, so there is no production evidence. Reference if ever turned on: [docs/cd-production-promotion.md](../../docs/cd-production-promotion.md).
