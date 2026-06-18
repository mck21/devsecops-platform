# Velero — install & backup/restore (Phase 8)

Cluster backup/restore for EKS, backed by S3 + EBS volume snapshots. Auth via
IRSA (no static keys).

## Prerequisites (Terraform)

- S3 bucket `mck21-devsecops-velero-backups`.
- IRSA role `mck21-devsecops-velero` with S3 read/write on that bucket and
  `ec2:CreateSnapshot` / `DescribeSnapshots` / `CreateTags` for EBS snapshots.

## Install (Helm)

```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

helm install velero vmware-tanzu/velero \
  --namespace velero --create-namespace \
  --set configuration.backupStorageLocation[0].name=default \
  --set configuration.backupStorageLocation[0].provider=aws \
  --set configuration.backupStorageLocation[0].bucket=mck21-devsecops-velero-backups \
  --set configuration.backupStorageLocation[0].config.region=us-east-1 \
  --set configuration.volumeSnapshotLocation[0].name=default \
  --set configuration.volumeSnapshotLocation[0].provider=aws \
  --set configuration.volumeSnapshotLocation[0].config.region=us-east-1 \
  --set initContainers[0].name=velero-plugin-for-aws \
  --set initContainers[0].image=velero/velero-plugin-for-aws:v1.10.0 \
  --set initContainers[0].volumeMounts[0].mountPath=/target \
  --set initContainers[0].volumeMounts[0].name=plugins \
  --set serviceAccount.server.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::125156866917:role/mck21-devsecops-velero
```

## Apply schedules

```bash
kubectl apply -f k8s/velero/schedules.yaml
velero schedule get
```

| Schedule | Cron | Scope | Retention |
|----------|------|-------|-----------|
| `daily-all-namespaces` | `0 1 * * *` | all namespaces | 7 days |
| `production-6h` | `0 */6 * * *` | production | 14 days |
| `daily-volumes` | `30 1 * * *` | staging, production PVs | 7 days |

## Restore drill

```bash
velero backup get
velero restore create --from-backup daily-all-namespaces-<timestamp>
velero restore describe <restore-name>
```

Full procedures (namespace restore, PostgreSQL point-in-time, tfstate recovery)
are in [../../docs/disaster-recovery.md](../../docs/disaster-recovery.md).
