# PostgreSQL StatefulSet on Kubernetes

This repository contains a StatefulSet configuration for running PostgreSQL database on Kubernetes with persistent storage.

## Overview

The setup includes:
- **StatefulSet**: Manages PostgreSQL pods with stable network identities and persistent storage
- **Headless Service**: Provides stable DNS entries for the StatefulSet pods
- **PersistentVolumeClaim**: Automatically provisions storage for database data
- **Health Checks**: Liveness and readiness probes to ensure database availability
- **Resource Limits**: CPU and memory constraints for resource management

## Prerequisites

- Kubernetes cluster (v1.19+)
- kubectl configured to communicate with your cluster
- A StorageClass available in your cluster (for dynamic volume provisioning)

Check available StorageClasses:
```bash
kubectl get storageclass
```

## Deployment

### 1. Review and Update Configuration

Before deploying, update the database credentials in `postgres-statefulset.yaml`:

```yaml
env:
- name: POSTGRES_PASSWORD
  value: "changeme"  # Change this!
```

For production, use a Secret instead:
```bash
kubectl create secret generic postgres-secret \
  --from-literal=postgres-password='your-secure-password'
```

Then reference it in the StatefulSet:
```yaml
env:
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: postgres-password
```

### 2. Deploy the StatefulSet

```bash
kubectl apply -f postgres-statefulset.yaml
```

### 3. Verify Deployment

Check the StatefulSet status:
```bash
kubectl get statefulset postgres
```

Check the pods:
```bash
kubectl get pods -l app=postgres
```

Check the PersistentVolumeClaims:
```bash
kubectl get pvc
```

Check the service:
```bash
kubectl get svc postgres
```

## Accessing PostgreSQL

### From Within the Cluster

Connect from another pod using the service DNS name:
```
postgres-0.postgres.default.svc.cluster.local:5432
```

Connection string format:
```
postgresql://admin:changeme@postgres-0.postgres.default.svc.cluster.local:5432/mydb
```

### Port Forwarding (for local access)

```bash
kubectl port-forward postgres-0 5432:5432
```

Then connect locally:
```bash
psql -h localhost -U admin -d mydb
# Password: changeme
```

Or using a PostgreSQL client:
```bash
psql postgresql://admin:changeme@localhost:5432/mydb
```

### Execute Commands in the Pod

Get a shell in the PostgreSQL pod:
```bash
kubectl exec -it postgres-0 -- bash
```

Connect to PostgreSQL directly:
```bash
kubectl exec -it postgres-0 -- psql -U admin -d mydb
```

## Management

### View Logs

```bash
kubectl logs postgres-0
```

Follow logs in real-time:
```bash
kubectl logs -f postgres-0
```

### Scale the StatefulSet

```bash
kubectl scale statefulset postgres --replicas=3
```

**Note**: PostgreSQL requires additional configuration for replication. This basic setup is for single-instance deployment.

### Delete the StatefulSet

Delete StatefulSet but keep PVCs (data persists):
```bash
kubectl delete statefulset postgres
```

Delete everything including data:
```bash
kubectl delete -f postgres-statefulset.yaml
kubectl delete pvc postgres-data-postgres-0
```

## Configuration

### Database Settings

The default configuration:
- **Database Name**: mydb
- **Username**: admin
- **Password**: changeme
- **Port**: 5432
- **Data Directory**: /var/lib/postgresql/data/pgdata

### Resource Limits

Current settings:
- Memory: 256Mi (request) / 512Mi (limit)
- CPU: 250m (request) / 500m (limit)
- Storage: 10Gi

Adjust these values in `postgres-statefulset.yaml` based on your workload.

### Storage

The StatefulSet uses a volumeClaimTemplate to automatically provision a 10Gi PersistentVolumeClaim for each pod. Modify the storage size as needed:

```yaml
volumeClaimTemplates:
- metadata:
    name: postgres-data
  spec:
    accessModes: ["ReadWriteOnce"]
    resources:
      requests:
        storage: 10Gi  # Adjust this value
```

## Troubleshooting

### Pod Not Starting

Check pod events:
```bash
kubectl describe pod postgres-0
```

### PVC Pending

Verify StorageClass exists:
```bash
kubectl get storageclass
```

If no default StorageClass exists, specify one in the volumeClaimTemplate:
```yaml
volumeClaimTemplates:
- metadata:
    name: postgres-data
  spec:
    storageClassName: your-storage-class
    accessModes: ["ReadWriteOnce"]
    resources:
      requests:
        storage: 10Gi
```

### Connection Issues

Verify the pod is ready:
```bash
kubectl get pods postgres-0
```

Check readiness probe status:
```bash
kubectl describe pod postgres-0 | grep -A 10 Readiness
```

## Security Considerations

1. **Change default password**: Never use the default password in production
2. **Use Secrets**: Store sensitive data in Kubernetes Secrets
3. **Network Policies**: Restrict access to PostgreSQL pods
4. **RBAC**: Implement proper role-based access control
5. **TLS/SSL**: Configure SSL for encrypted connections
6. **Regular Backups**: Implement a backup strategy for your data

## Backup and Restore

### Create a Backup

```bash
kubectl exec postgres-0 -- pg_dump -U admin mydb > backup.sql
```

### Restore from Backup

```bash
kubectl exec -i postgres-0 -- psql -U admin mydb < backup.sql
```

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
