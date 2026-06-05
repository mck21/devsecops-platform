# ArgoCD Installation

## Dev (Minikube)
Installed via official stable manifest:
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Access:
kubectl port-forward svc/argocd-server -n argocd 8080:443
URL: https://localhost:8080
User: admin

## Staging/Production (EKS)
Installed via Helm in Phase 5.