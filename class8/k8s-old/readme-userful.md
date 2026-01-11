# Kubectl Context and EKS Cluster Management Guide

This guide covers managing Kubernetes contexts and EKS clusters using kubectl and AWS CLI commands.

## Table of Contents
- [Kubectl Context Commands](#kubectl-context-commands)
- [EKS Cluster Commands](#eks-cluster-commands)
- [Working with AWS Profiles](#working-with-aws-profiles)
- [Service Discovery](#service-discovery)
- [Kubernetes nodeSelector Options](#kubernetes-nodeselector-options)
- [Best Practices](#best-practices)
- [Useful Scripts](#useful-scripts)

## Kubectl Context Commands

### Basic Context Operations

```bash

# add the cluster to config
aws eks update-kubeconfig --name <cluster-name> --region <region>

aws eks update-kubeconfig --name may25-dev-cluster --region ap-south-1

# List all contexts
kubectl config get-contexts

# List contexts with detailed info
kubectl config get-contexts -o wide

# Get current context
kubectl config current-context

# Switch context
kubectl config use-context <context-name>

# Switch to previous context (with kubectx)
kubectx -
```

### Context Management

```bash
# Create/set context
kubectl config set-context <context-name> \
  --cluster=<cluster> \
  --user=<user> \
  --namespace=<namespace>

# Rename context
kubectl config rename-context <old-name> <new-name>

# Delete context
kubectl config delete-context <context-name>

# Set default namespace for current context
kubectl config set-context --current --namespace=<namespace>
```

### View Configuration

```bash
# View entire kubeconfig
kubectl config view

# View specific context
kubectl config view --context=<context-name>

# View current context details
kubectl config view --minify
```

## EKS Cluster Commands

### List and Describe Clusters

```bash
# List clusters in default region
aws eks list-clusters

# List clusters in specific region
aws eks list-clusters --region us-west-2

# List clusters with specific profile
aws eks list-clusters --profile production

# Get detailed cluster info
aws eks describe-cluster --name <cluster-name> --region <region>

# Check cluster status
aws eks describe-cluster --name <cluster-name> --query 'cluster.status'
```

### Add EKS Clusters to Kubeconfig

```bash
# Basic cluster addition
aws eks update-kubeconfig --name <cluster-name> --region <region>

# With custom context name (alias)
aws eks update-kubeconfig \
  --name <cluster-name> \
  --region <region> \
  --alias <custom-context-name>

# With specific AWS profile
aws eks update-kubeconfig \
  --name <cluster-name> \
  --region <region> \
  --profile <aws-profile>

# Combined: profile + custom alias
aws eks update-kubeconfig \
  --name production-cluster \
  --region us-east-1 \
  --profile prod-account \
  --alias prod
```

## Working with AWS Profiles

### Profile-based EKS Management

```bash
# List profiles
aws configure list-profiles

# Set default profile for session
export AWS_PROFILE=production

# Add clusters with different profiles
aws eks update-kubeconfig \
  --name prod-cluster \
  --region us-east-1 \
  --profile production \
  --alias prod

aws eks update-kubeconfig \
  --name staging-cluster \
  --region us-west-2 \
  --profile staging \
  --alias staging

aws eks update-kubeconfig \
  --name dev-cluster \
  --region us-east-1 \
  --profile development \
  --alias dev
```

### Multi-Account Setup Example

```bash
# Production Account (Profile: prod-account)
aws eks update-kubeconfig \
  --name production-cluster \
  --region us-east-1 \
  --profile prod-account \
  --alias prod-east

aws eks update-kubeconfig \
  --name production-west \
  --region us-west-2 \
  --profile prod-account \
  --alias prod-west

# Staging Account (Profile: staging-account)
aws eks update-kubeconfig \
  --name staging-cluster \
  --region us-east-1 \
  --profile staging-account \
  --alias staging

# Development Account (Profile: dev-account)
aws eks update-kubeconfig \
  --name dev-cluster \
  --region us-east-1 \
  --profile dev-account \
  --alias dev
```

## Service Discovery

### Using DNS (Recommended)

```bash
# Same namespace
curl http://my-service:8080

# Different namespace
curl http://service-name.namespace:8080

# Fully qualified domain name
curl http://service-name.namespace.svc.cluster.local:8080
```

### Using Environment Variables

Kubernetes automatically creates environment variables for services:

```bash
# Format: {SERVICE_NAME}_SERVICE_HOST and {SERVICE_NAME}_SERVICE_PORT
echo $MY_DATABASE_SERVICE_HOST    # 10.96.45.123
echo $MY_DATABASE_SERVICE_PORT    # 5432
```

### Service Discovery Commands

```bash
# List services
kubectl get services
kubectl get svc -A  # All namespaces

# Get service endpoints
kubectl get endpoints <service-name>

# Test DNS resolution from pod
kubectl exec -it <pod-name> -- nslookup <service-name>
kubectl exec -it <pod-name> -- dig <service-name>.default.svc.cluster.local

# Check environment variables in pod
kubectl exec <pod-name> -- env | grep SERVICE
```

## Kubernetes nodeSelector Options

### Basic nodeSelector

```yaml
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    disktype: ssd
    zone: us-west-1
```

### Built-in Node Labels

```yaml
spec:
  nodeSelector:
    kubernetes.io/hostname: worker-node-1
    kubernetes.io/os: linux
    kubernetes.io/arch: amd64
    node.kubernetes.io/instance-type: m5.large
    topology.kubernetes.io/zone: us-west-1a
    topology.kubernetes.io/region: us-west-1
```

### Custom Labels Examples

```yaml
spec:
  nodeSelector:
    environment: production
    workload-type: gpu-intensive
    storage: high-iops
    team: data-science
```

### Advanced Alternatives

**Node Affinity:**
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values: ["ssd", "nvme"]
```

**Taints and Tolerations:**
```yaml
spec:
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

## Best Practices

### Context Naming Conventions

```bash
# Good naming patterns
prod                    # Simple environment name
staging-west           # Environment + region
gke-prod              # Cloud provider + environment
aws-dev-east          # Cloud + environment + region
```

### Context Management Workflow

```bash
# 1. Add cluster with meaningful alias
aws eks update-kubeconfig \
  --name production-cluster \
  --region us-east-1 \
  --profile prod \
  --alias prod

# 2. Verify and test connection
kubectl config get-contexts
kubectl config use-context prod
kubectl cluster-info
kubectl get nodes

# 3. Set default namespace if needed
kubectl config set-context --current --namespace=production
```

### Security Best Practices

- Use separate AWS profiles for different environments
- Implement least-privilege IAM policies for EKS access
- Regularly rotate AWS credentials
- Use temporary credentials when possible

## Useful Scripts

### Batch Context Renaming

```bash
#!/bin/bash
# rename-contexts.sh

declare -A renames=(
  ["arn:aws:eks:us-east-1:123456789:cluster/prod"]="prod"
  ["arn:aws:eks:us-east-1:123456789:cluster/staging"]="staging"
  ["docker-desktop"]="local"
)

for old_name in "${!renames[@]}"; do
  new_name="${renames[$old_name]}"
  echo "Renaming: $old_name -> $new_name"
  kubectl config rename-context "$old_name" "$new_name"
done
```

### List All EKS Clusters Across Regions

```bash
#!/bin/bash
# list-all-eks-clusters.sh

echo "Listing EKS clusters across all regions..."

for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  echo -e "\n📍 Region: $region"
  clusters=$(aws eks list-clusters --region $region --query 'clusters' --output text 2>/dev/null)
  
  if [ -n "$clusters" ] && [ "$clusters" != "None" ]; then
    echo "$clusters"
  else
    echo "  No clusters found"
  fi
done
```

### Multi-Account EKS Setup

```bash
#!/bin/bash
# setup-multi-account-eks.sh

# Production clusters
echo "Setting up production clusters..."
aws eks update-kubeconfig --name prod-east --region us-east-1 --profile prod --alias prod-east
aws eks update-kubeconfig --name prod-west --region us-west-2 --profile prod --alias prod-west

# Staging clusters
echo "Setting up staging clusters..."
aws eks update-kubeconfig --name staging-cluster --region us-east-1 --profile staging --alias staging

# Development clusters
echo "Setting up development clusters..."
aws eks update-kubeconfig --name dev-cluster --region us-east-1 --profile dev --alias dev

echo "✅ All clusters configured!"
kubectl config get-contexts
```

### Context Switching Helper

```bash
#!/bin/bash
# switch-context.sh

if [ $# -eq 0 ]; then
  echo "Available contexts:"
  kubectl config get-contexts
  echo ""
  echo "Usage: $0 <context-name>"
  exit 1
fi

CONTEXT=$1
kubectl config use-context $CONTEXT

if [ $? -eq 0 ]; then
  echo "✅ Switched to context: $CONTEXT"
  echo "📍 Cluster info:"
  kubectl cluster-info
  echo "🏷️  Current namespace: $(kubectl config view --minify --output 'jsonpath={..namespace}')"
else
  echo "❌ Failed to switch to context: $CONTEXT"
fi
```

## Useful Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
# Kubectl shortcuts
alias k='kubectl'
alias kgc='kubectl config get-contexts'
alias kcc='kubectl config current-context'
alias kuc='kubectl config use-context'
alias ksc='kubectl config set-context'

# EKS shortcuts
alias eks-list='aws eks list-clusters'
alias eks-desc='aws eks describe-cluster --name'
alias eks-update='aws eks update-kubeconfig'

# Service discovery
alias kgs='kubectl get services'
alias kge='kubectl get endpoints'
alias kgp='kubectl get pods'
```

## Troubleshooting

### Common Issues and Solutions

```bash
# Context doesn't exist
kubectl config get-contexts | grep <partial-name>

# Permission denied
aws sts get-caller-identity  # Check current AWS identity
kubectl auth can-i '*' '*'  # Check cluster permissions

# Connection issues
kubectl cluster-info
kubectl get nodes

# Profile issues
aws configure list-profiles
export AWS_PROFILE=<profile-name>
```

### Verification Commands

```bash
# Verify AWS configuration
aws sts get-caller-identity
aws configure list

# Verify kubectl configuration
kubectl config view
kubectl config current-context
kubectl cluster-info

# Test cluster connectivity
kubectl get nodes
kubectl get namespaces
kubectl auth can-i get pods
```

---

**Remember**: Always verify your context before running commands in production environments!