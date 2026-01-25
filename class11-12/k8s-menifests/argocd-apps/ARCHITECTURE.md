# ArgoCD App of Apps Architecture Diagram

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                             │
│  k8s-bootcamp-dec25/class11-12/k8s-menifests/                        │
│                                                                       │
│  ├── argocd-apps/                                                    │
│  │   ├── apps/root-app.yaml          (Parent Application)           │
│  │   ├── frontend/application.yaml   (Child App Definition)         │
│  │   ├── catalogue/application.yaml  (Child App Definition)         │
│  │   ├── voting/application.yaml     (Child App Definition)         │
│  │   └── recommendation/application.yaml (Child App Definition)     │
│  │                                                                   │
│  ├── 02-frontend-deployment.yaml     (Actual K8s Manifests)         │
│  ├── 03-catalogue-deployment.yaml                                    │
│  ├── 04-voting-deployment.yaml                                       │
│  └── 05-recommendation-deployment.yaml                               │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
                                │ Git Sync
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         ArgoCD Control Plane                          │
│                         (argocd namespace)                            │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              craftista-root-app (Parent)                       │ │
│  │                                                                 │ │
│  │  - Watches: argocd-apps/**/application.yaml                   │ │
│  │  - Auto-sync: Enabled                                         │ │
│  │  - Self-heal: Enabled                                         │ │
│  │  - Creates child Application CRDs                             │ │
│  └────────────────┬───────────────────────────────────────────────┘ │
│                   │                                                  │
│                   │ Manages (Creates & Updates)                      │
│                   │                                                  │
│       ┌───────────┼───────────┬─────────────┬──────────────┐        │
│       ▼           ▼           ▼             ▼              ▼        │
│  ┌─────────┐┌──────────┐┌─────────┐┌───────────────────┐          │
│  │Frontend ││Catalogue ││ Voting  ││ Recommendation    │          │
│  │   App   ││   App    ││   App   ││      App          │          │
│  │         ││          ││         ││                   │          │
│  │ Status: ││ Status:  ││ Status: ││ Status:           │          │
│  │ Synced  ││ Synced   ││ Synced  ││ Synced            │          │
│  │ Healthy ││ Healthy  ││ Healthy ││ Healthy           │          │
│  └────┬────┘└────┬─────┘└────┬────┘└────┬──────────────┘          │
│       │          │            │          │                          │
└───────┼──────────┼────────────┼──────────┼──────────────────────────┘
        │          │            │          │
        │ Deploys  │ Deploys    │ Deploys  │ Deploys
        │          │            │          │
        ▼          ▼            ▼          ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                                 │
│                    craftista namespace                                │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐                         │
│  │   Frontend       │  │   Catalogue      │                         │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │                         │
│  │ │ Deployment   │ │  │ │ Deployment   │ │                         │
│  │ │ Replicas: 2  │ │  │ │ Replicas: 2  │ │                         │
│  │ └──────────────┘ │  │ └──────────────┘ │                         │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │                         │
│  │ │   Service    │ │  │ │   Service    │ │                         │
│  │ │ Port: 80     │ │  │ │ Port: 5000   │ │                         │
│  │ └──────────────┘ │  │ └──────────────┘ │                         │
│  └──────────────────┘  └──────────────────┘                         │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐                         │
│  │   Voting         │  │  Recommendation  │                         │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │                         │
│  │ │ Deployment   │ │  │ │ Deployment   │ │                         │
│  │ │ Replicas: 2  │ │  │ │ Replicas: 2  │ │                         │
│  │ └──────────────┘ │  │ └──────────────┘ │                         │
│  │ ┌──────────────┐ │  │ ┌──────────────┐ │                         │
│  │ │   Service    │ │  │ │   Service    │ │                         │
│  │ │ Port: 8080   │ │  │ │ Port: 8080   │ │                         │
│  │ └──────────────┘ │  │ └──────────────┘ │                         │
│  └──────────────────┘  └──────────────────┘                         │
└──────────────────────────────────────────────────────────────────────┘
```

## Workflow Sequence

```
1. Developer pushes changes to Git
   └─> GitHub Repository Updated

2. ArgoCD detects changes (every 3 minutes by default)
   └─> Root App polls: argocd-apps/**/application.yaml

3. Root App processes changes
   ├─> Creates/Updates child Application CRDs in argocd namespace
   └─> Each child app is a Kubernetes resource of kind: Application

4. Each child app syncs independently
   ├─> Frontend App syncs 02-frontend-deployment.yaml
   ├─> Catalogue App syncs 03-catalogue-deployment.yaml
   ├─> Voting App syncs 04-voting-deployment.yaml
   └─> Recommendation App syncs 05-recommendation-deployment.yaml

5. ArgoCD applies manifests to cluster
   └─> Deployments, Services, ConfigMaps created in craftista namespace

6. Self-healing active
   ├─> If manual changes made to cluster → ArgoCD reverts them
   └─> If pods deleted → ArgoCD recreates them
```

## Application Relationship

```
craftista-root-app (metadata.name)
    │
    ├─ Manages ─> Application: frontend
    │              ├─ namespace: argocd (Application CRD location)
    │              ├─ destination.namespace: craftista (where resources deploy)
    │              └─ source.path: ../02-frontend-deployment.yaml
    │
    ├─ Manages ─> Application: catalogue
    │              ├─ namespace: argocd
    │              ├─ destination.namespace: craftista
    │              └─ source.path: ../03-catalogue-deployment.yaml
    │
    ├─ Manages ─> Application: voting
    │              ├─ namespace: argocd
    │              ├─ destination.namespace: craftista
    │              └─ source.path: ../04-voting-deployment.yaml
    │
    └─ Manages ─> Application: recommendation
                   ├─ namespace: argocd
                   ├─ destination.namespace: craftista
                   └─ source.path: ../05-recommendation-deployment.yaml
```

## Data Flow

```
User Request
    │
    ▼
┌─────────────┐
│  Frontend   │ :80 (Service)
│   Pod:3000  │
└──────┬──────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌──────────────┐   ┌──────────────┐
│  Catalogue   │   │    Voting    │
│  Pod:5000    │   │   Pod:8080   │
└──────────────┘   └──────────────┘
       │
       ▼
┌──────────────────┐
│ Recommendation   │
│   Pod:8080       │
└──────────────────┘
```

## Key Components

### Root Application (apps/root-app.yaml)
- **Purpose**: Manages all child applications
- **Watches**: `argocd-apps/` directory (excluding apps/ folder)
- **Creates**: Application CRDs in argocd namespace
- **Sync**: Automated with self-heal

### Child Applications
Each child application:
- **Lives in**: argocd namespace (as Application CRD)
- **Deploys to**: craftista namespace
- **Source**: Points to specific YAML files in Git
- **Sync Policy**: Automated, prune enabled, self-heal enabled

## Advantages

1. **Declarative**: Everything defined in Git
2. **Automated**: No manual kubectl apply needed
3. **Scalable**: Add new microservices easily
4. **Auditable**: All changes tracked in Git
5. **Resilient**: Self-healing prevents drift
6. **Organized**: Clear separation of concerns

## Environment Promotion Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                  Multi-Environment Setup                     │
│                                                              │
│  dev/                                                        │
│  ├── argocd-apps/                                           │
│  │   ├── apps/root-app-dev.yaml                            │
│  │   └── */application.yaml (targetRevision: develop)      │
│  │                                                          │
│  staging/                                                   │
│  ├── argocd-apps/                                           │
│  │   ├── apps/root-app-staging.yaml                        │
│  │   └── */application.yaml (targetRevision: staging)      │
│  │                                                          │
│  production/                                                │
│  └── argocd-apps/                                           │
│      ├── apps/root-app-prod.yaml                           │
│      └── */application.yaml (targetRevision: main)         │
└─────────────────────────────────────────────────────────────┘
```

## Security Considerations

1. **RBAC**: ArgoCD service account needs proper permissions
2. **Git Access**: Use SSH keys or tokens for private repos
3. **Namespace Isolation**: Each environment in separate namespace
4. **Image Security**: Use private ECR with proper IAM roles
5. **Secrets Management**: Consider sealed-secrets or external-secrets

## Monitoring & Observability

```bash
# Application Health
kubectl get applications -n argocd

# Application Details
kubectl describe application frontend -n argocd

# Sync Status
argocd app list

# Live Logs
argocd app logs frontend --follow

# Diff between Git and Cluster
argocd app diff frontend
```
