# ADR-002: EKS over ECS

## Status
Accepted

## Context
The platform needs a container orchestrator on AWS. ECS/Fargate is simpler and
cheaper to operate; EKS is managed Kubernetes. The project's goal is to
demonstrate portable, industry-standard Kubernetes + ecosystem skills (Istio,
ArgoCD, Kyverno, Prometheus), and to run the *same* manifests locally on Minikube.

## Decision
Use **EKS**. Kubernetes is the portable target: identical manifests run on
Minikube (dev) and EKS (staging/production) via Kustomize overlays, and the whole
CNCF tooling stack (Istio, ArgoCD, Kyverno, External Secrets, kube-prometheus)
assumes Kubernetes.

## Consequences
- **Easier:** one manifest set across local and cloud; access to the CNCF
  ecosystem; transferable skills.
- **Harder / cost:** EKS control plane (~$73/mo) and operational complexity vs
  ECS. Mitigated with Spot nodes, single-AZ NAT on staging, off-hours shutdown,
  and running **staging-only** during showcase.
