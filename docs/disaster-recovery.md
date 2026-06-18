# Disaster Recovery Runbook (Phase 8)

How the platform is backed up and how to recover from data, namespace, or state
loss. Backups use **Velero** (cluster + EBS snapshots) and AWS-native snapshots.

## Backup inventory

| What | Tool | Schedule | Retention | Location |
|------|------|----------|-----------|----------|
| All namespaces (manifests + PVs) | Velero | daily 01:00 | 7 days | S3 `mck21-devsecops-velero-backups` |
| Production namespace | Velero | every 6h | 14 days | S3 |
| PV data (postgres/redis) | Velero fs-backup | daily 01:30 | 7 days | S3 |
| Terraform state | S3 versioning | on write | versioned | S3 `devsecops-tfstate-125156866917` |

Install + schedule definitions: [../k8s/velero/install-notes.md](../k8s/velero/install-notes.md),
[../k8s/velero/schedules.yaml](../k8s/velero/schedules.yaml).

## RTO / RPO targets

| Scenario | RPO (data loss) | RTO (time to restore) |
|----------|-----------------|------------------------|
| Production namespace loss | ≤ 6h | ≤ 30 min |
| Full cluster loss | ≤ 24h | ≤ 2h (terraform apply + restore) |
| PostgreSQL corruption | ≤ 6h (or 5 min with RDS PITR) | ≤ 30 min |

## Procedure 1 — Restore a namespace

```bash
velero backup get
velero restore create prod-restore --from-backup production-6h-<timestamp>
velero restore describe prod-restore --details
kubectl get pods -n production
```

Then let ArgoCD re-sync to reconcile any drift:
```bash
argocd app sync feature-flags-production   # only if production runtime is on
```

## Procedure 2 — PostgreSQL point-in-time

- **In-cluster postgres (dev/showcase):** restore the PV via the `daily-volumes`
  Velero backup, then `kubectl rollout restart deployment/postgres`.
- **Managed RDS (recommended for prod runtime):** use RDS automated snapshots /
  PITR: `aws rds restore-db-instance-to-point-in-time ...` then repoint
  `DATABASE_URL` (via External Secrets / AWS Secrets Manager).

## Procedure 3 — Full cluster rebuild

1. `terraform apply` the environment (recreates VPC/EKS/ECR).
2. Bootstrap the platform (Istio, Ingress, cert-manager, ArgoCD) per
   [../k8s/argocd/install-notes.md](../k8s/argocd/install-notes.md).
3. Reinstall Velero (same S3 location auto-discovers backups).
4. `velero restore create --from-backup daily-all-namespaces-<timestamp>`.
5. ArgoCD reconciles app state from Git.

## Procedure 4 — Terraform state corruption

- State is versioned in S3 with `use_lockfile = true`. Recover a prior version:
  ```bash
  aws s3api list-object-versions --bucket devsecops-tfstate-125156866917 \
    --prefix staging/terraform.tfstate
  aws s3api get-object --bucket devsecops-tfstate-125156866917 \
    --key staging/terraform.tfstate --version-id <id> terraform.tfstate
  ```
- If a lock is stuck: `terraform force-unlock <LOCK_ID>`.

## Verification

DR is only real if tested — see the namespace-restore and secret-rotation drills
in [resilience-testing.md](resilience-testing.md). Run a restore drill quarterly.
