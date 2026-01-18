kubectl set image deployment <deployment-name> <container-name>=<new-image>:<tag>


kubectl rollout status deployment <deployment-name>

kubectl rollout undo deployment <deployment-name>



- install minikube, start and all

- install argocd

# ArgoCD on Minikube

## Start Minikube
```bash
minikube start
```

## Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Wait for Pods
```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

## Get Initial Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Access ArgoCD UI (Port Forward)
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access at: https://localhost:8080
- Username: `admin`
- Password: (from step above)

## Alternative: Access via NodePort
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
minikube service argocd-server -n argocd
```

## Login via CLI
```bash
argocd login localhost:8080 --username admin --password <password> --insecure
```

## Change Admin Password (Optional)
```bash
argocd account update-password
```