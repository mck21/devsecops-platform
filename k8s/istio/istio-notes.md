## Staging / Production (EKS)

Install Istio with the production profile during Phase 5 bootstrap:

```bash
istioctl install --set profile=production -y
kubectl label namespace staging istio-injection=enabled --overwrite
```

Sidecar injection enabled on namespaces:

- staging
- production

Full bootstrap: [k8s/argocd/install-notes.md](../argocd/install-notes.md).
