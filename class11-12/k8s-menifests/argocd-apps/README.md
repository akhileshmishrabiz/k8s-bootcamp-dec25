# ArgoCD App of Apps Architecture for Craftista Microservices

## Architecture Overview

This directory implements the **App of Apps** pattern for deploying the Craftista microservices platform using ArgoCD.

```
┌─────────────────────────────────────────────────────────────┐
│                    ArgoCD Server                             │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         craftista-root-app (Parent App)            │    │
│  │                                                     │    │
│  │  Watches: argocd-apps/**/application.yaml          │    │
│  │  Manages all child applications                    │    │
│  └──────────┬──────────────────────────────────────┬──┘    │
│             │                                      │        │
│             ▼                                      ▼        │
│  ┌──────────────────┐                  ┌──────────────────┐│
│  │  Child Apps      │                  │  Child Apps      ││
│  │                  │                  │                  ││
│  │ ┌──────────────┐ │                  │ ┌──────────────┐││
│  │ │  Frontend    │ │                  │ │  Voting      │││
│  │ └──────────────┘ │                  │ └──────────────┘││
│  │                  │                  │                  ││
│  │ ┌──────────────┐ │                  │ ┌──────────────┐││
│  │ │  Catalogue   │ │                  │ │Recommendation│││
│  │ └──────────────┘ │                  │ └──────────────┘││
│  └──────────────────┘                  └──────────────────┘│
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 Kubernetes Cluster                           │
│                                                              │
│           Namespace: craftista                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐│
│  │ Frontend │  │Catalogue │  │  Voting  │  │Recommendation││
│  │ Pods     │  │ Pods     │  │  Pods    │  │  Pods       ││
│  │ Service  │  │ Service  │  │  Service │  │  Service    ││
│  └──────────┘  └──────────┘  └──────────┘  └─────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
argocd-apps/
├── apps/
│   └── root-app.yaml              # Parent Application (App of Apps)
├── frontend/
│   └── application.yaml           # Frontend Application manifest
├── catalogue/
│   └── application.yaml           # Catalogue Application manifest
├── voting/
│   └── application.yaml           # Voting Application manifest
├── recommendation/
│   └── application.yaml           # Recommendation Application manifest
└── README.md                      # This file
```

## How It Works

### 1. Root Application (App of Apps)
The `apps/root-app.yaml` is the parent application that:
- Watches the `argocd-apps/` directory
- Automatically discovers all child application manifests
- Creates and manages child applications in ArgoCD
- Provides centralized control over all microservices

### 2. Child Applications
Each microservice has its own Application manifest that:
- Points to the specific deployment YAML in the repository
- Manages the lifecycle of that microservice
- Handles automatic sync, pruning, and self-healing
- Deploys to the `craftista` namespace

## Key Features

### Automated Sync
- **Enabled**: Changes in Git automatically trigger deployments
- **Self-Heal**: ArgoCD automatically corrects drift from desired state
- **Prune**: Deleted resources in Git are automatically removed from cluster

### Retry Policy
- **5 retries** with exponential backoff
- Starts at 5s, increases by factor of 2
- Maximum retry duration: 3 minutes

### Sync Options
- **CreateNamespace**: Automatically creates the `craftista` namespace
- **PrunePropagationPolicy**: Ensures proper deletion order
- **PruneLast**: Deletes resources after new ones are healthy

## Deployment Instructions

### Prerequisites
1. ArgoCD installed in your Kubernetes cluster
2. Access to the Kubernetes cluster
3. Git repository access configured in ArgoCD

### Step 1: Install ArgoCD (if not already installed)
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 2: Access ArgoCD UI
```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access: https://localhost:8080
# Username: admin
# Password: (from above command)
```

### Step 3: Deploy the Root Application
```bash
# Apply the root app (this will create all child apps)
kubectl apply -f argocd-apps/apps/root-app.yaml
```

### Step 4: Monitor Deployment
```bash
# Watch ArgoCD applications
kubectl get applications -n argocd

# Watch pods in craftista namespace
kubectl get pods -n craftista -w

# Check sync status
argocd app list
```

## Managing Applications

### Sync All Applications
```bash
argocd app sync craftista-root-app --prune
```

### Sync Individual Service
```bash
argocd app sync frontend
argocd app sync catalogue
argocd app sync voting
argocd app sync recommendation
```

### View Application Details
```bash
argocd app get frontend
```

### Rollback an Application
```bash
argocd app rollback frontend
```

### Delete All Applications
```bash
kubectl delete -f argocd-apps/apps/root-app.yaml
```

## Benefits of App of Apps Pattern

1. **Single Source of Truth**: One root application manages all microservices
2. **Easy Onboarding**: Add new microservices by creating a new application.yaml
3. **Consistent Configuration**: All apps follow the same sync policies
4. **Simplified Management**: Control all apps through the root application
5. **GitOps Workflow**: All changes tracked in Git
6. **Environment Separation**: Easy to replicate for dev/staging/prod

## Microservices Deployed

| Service | Port | Dependencies |
|---------|------|--------------|
| Frontend | 3000 | catalogue, voting, recommendation |
| Catalogue | 5000 | None |
| Voting | 8080 | None |
| Recommendation | 8080 | None |

## Customization

### Changing Git Repository
Edit the `repoURL` in each application.yaml:
```yaml
source:
  repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
```

### Changing Target Branch
Edit the `targetRevision` in each application.yaml:
```yaml
source:
  targetRevision: develop  # or any branch/tag
```

### Disabling Auto-Sync
Remove or set to false in application.yaml:
```yaml
syncPolicy:
  automated: null  # Disables auto-sync
```

## Troubleshooting

### Application Not Syncing
```bash
# Check application status
argocd app get <app-name>

# View sync errors
kubectl describe application <app-name> -n argocd

# Manual sync with prune
argocd app sync <app-name> --prune --force
```

### Pods Not Starting
```bash
# Check pod status
kubectl get pods -n craftista

# View pod logs
kubectl logs -n craftista <pod-name>

# Describe pod for events
kubectl describe pod -n craftista <pod-name>
```

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
