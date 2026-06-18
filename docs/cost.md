# Cost Estimates

Approximate monthly AWS cost per environment (us-east-1, on-demand list prices;
Spot reduces EC2 ~70%). Dev runs on Minikube (local) so it is effectively free
apart from shared S3/ECR.

## Per-environment

| Resource | Dev (Minikube) | Staging (EKS) | Production (EKS) |
|----------|----------------|---------------|------------------|
| EKS control plane | $0 | ~$73 | ~$73 |
| EC2 nodes (Spot) | $0 | ~$30 | ~$60 |
| NAT Gateway | $0 | ~$32 (single-AZ) | ~$64 (multi-AZ) |
| S3 + state/locking | ~$1 | ~$2 | ~$2 |
| ECR storage | ~$1 | ~$1 | ~$1 |
| EBS volumes (Prometheus/Loki/PV) | $0 | ~$10 | ~$20 |
| Secrets Manager | $0 | ~$1 | ~$1 |
| **Estimated total** | **~$2/mo** | **~$149/mo** | **~$221/mo** |

> Production is **off** during showcase, so the production column is the projected
> cost if its runtime were enabled — it currently incurs **$0**.

## Cost controls in place

- **Spot** node groups on staging (and burst on production).
- **Single-AZ NAT** on staging; multi-AZ only on production.
- Staging can be **shut down outside working hours** (~60% saving): scale node
  group to 0 or `terraform destroy` the cluster (state + ECR persist).
- ECR lifecycle policy: 10 images staging / 20 production.
- Prometheus/Loki retention tuned per env (2d dev, 15d/7d EKS).

## Showcase footprint

Running **staging only** keeps the live bill near **~$149/mo**, or lower with
off-hours shutdown. Dev/local validation is free.

## Cost observability

A Grafana CI/CD + cost panel and AWS Cost Explorer tags (`environment`,
`project=mck21-devsecops`) make spend attributable per environment.
