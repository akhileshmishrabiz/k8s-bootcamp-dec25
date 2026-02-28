# OpenSearch StatefulSet for Production on AWS EKS

This folder contains production-ready configuration for running a 3-node OpenSearch cluster on Kubernetes using AWS EBS CSI driver for persistent storage.

## Architecture

- **3 OpenSearch Pods**: Highly available cluster with 3 master-eligible data nodes
- **AWS EBS CSI Driver**: Uses GP3 volumes for persistent storage
- **Headless Service**: For internal cluster communication
- **LoadBalancer Service**: For external access to the cluster
- **ConfigMap**: OpenSearch configuration
- **StatefulSet**: Manages the OpenSearch pods with stable identities

## Prerequisites

### 1. AWS EBS CSI Driver Installation

The AWS EBS CSI driver must be installed in your EKS cluster.

Install via EKS add-on (recommended):
```bash
aws eks create-addon \
  --cluster-name your-cluster-name \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole
```

Or install via Helm:
```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm upgrade --install aws-ebs-csi-driver \
  --namespace kube-system \
  aws-ebs-csi-driver/aws-ebs-csi-driver
```

Verify installation:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

### 2. IAM Permissions

Ensure your EKS node IAM role has the following policy attached:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumeStatus",
        "ec2:CreateSnapshot",
        "ec2:DeleteSnapshot",
        "ec2:DescribeSnapshots",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Kubernetes Cluster Requirements

- Kubernetes 1.20+
- At least 3 worker nodes (for pod distribution)
- Each node should have at least 4 CPU cores and 8GB RAM available

## Deployment

### Step 1: Create StorageClass

Deploy the AWS EBS StorageClass:
```bash
kubectl apply -f aws-ebs-storageclass.yaml
```

Verify:
```bash
kubectl get storageclass ebs-sc
```

### Step 2: Deploy OpenSearch Cluster

Deploy the OpenSearch StatefulSet:
```bash
kubectl apply -f opensearch-statefulset.yaml
```

### Step 3: Monitor Deployment

Watch the pods come up:
```bash
kubectl get pods -l app=opensearch -w
```

Check StatefulSet status:
```bash
kubectl get statefulset opensearch
```

Check PVCs:
```bash
kubectl get pvc
```

View EBS volumes in AWS:
```bash
aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/created-for/pvc/name,Values=opensearch-data-*"
```

## Verification

### Check Cluster Health

Port forward to access OpenSearch:
```bash
kubectl port-forward opensearch-0 9200:9200
```

Check cluster health:
```bash
curl http://localhost:9200/_cluster/health?pretty
```

Expected output:
```json
{
  "cluster_name" : "opensearch-cluster",
  "status" : "green",
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  ...
}
```

List all nodes:
```bash
curl http://localhost:9200/_cat/nodes?v
```

Check indices:
```bash
curl http://localhost:9200/_cat/indices?v
```

## Accessing OpenSearch

### From Within the Cluster

Use the headless service DNS:
```
opensearch-0.opensearch-cluster.default.svc.cluster.local:9200
opensearch-1.opensearch-cluster.default.svc.cluster.local:9200
opensearch-2.opensearch-cluster.default.svc.cluster.local:9200
```

Or use the LoadBalancer service:
```
opensearch.default.svc.cluster.local:9200
```

### From Outside the Cluster

Get the LoadBalancer endpoint:
```bash
kubectl get svc opensearch
```

Access via the EXTERNAL-IP:
```bash
curl http://<EXTERNAL-IP>:9200/_cluster/health?pretty
```

### Port Forwarding (Development)

```bash
kubectl port-forward svc/opensearch 9200:9200
```

Then access locally:
```bash
curl http://localhost:9200
```

## Configuration

### Storage

- **StorageClass**: `ebs-sc` (AWS EBS GP3)
- **Volume Size**: 50Gi per pod
- **IOPS**: 3000
- **Throughput**: 125 MB/s
- **Encryption**: Enabled
- **Reclaim Policy**: Retain (data persists after pod deletion)

To modify storage size, edit `opensearch-statefulset.yaml`:
```yaml
volumeClaimTemplates:
  - metadata:
      name: opensearch-data
    spec:
      resources:
        requests:
          storage: 100Gi  # Change this
```

### Resources

Current allocation per pod:
- **Memory**: 3Gi request / 4Gi limit
- **CPU**: 1000m request / 2000m limit
- **JVM Heap**: 2GB (set via OPENSEARCH_JAVA_OPTS)

Adjust based on workload:
```yaml
resources:
  requests:
    memory: "6Gi"
    cpu: "2000m"
  limits:
    memory: "8Gi"
    cpu: "4000m"
```

### Cluster Settings

The cluster is configured with:
- 3 master-eligible nodes
- 3 data nodes
- Initial master nodes: opensearch-0, opensearch-1, opensearch-2
- Discovery via DNS seed hosts
- Security plugin enabled (default passwords)

## Scaling

### Scale Up

To add more nodes:
```bash
kubectl scale statefulset opensearch --replicas=5
```

**Important**: Update the `cluster.initial_master_nodes` only for initial bootstrap. Don't change it after cluster is running.

### Scale Down

```bash
kubectl scale statefulset opensearch --replicas=3
```

**Warning**: Always scale down gradually and ensure data is replicated before removing nodes.

## Security

### Default Credentials

OpenSearch comes with default credentials:
- **Username**: admin
- **Password**: admin

Access with credentials:
```bash
curl -u admin:admin http://localhost:9200/_cluster/health?pretty
```

### Production Security Setup

For production, you should:

1. **Change default passwords**:
```bash
kubectl exec -it opensearch-0 -- bash
cd /usr/share/opensearch/plugins/opensearch-security/tools
./hash.sh -p your-new-password
```

2. **Enable TLS/SSL**: Update the ConfigMap to enable SSL:
```yaml
plugins.security.ssl.http.enabled: true
plugins.security.ssl.transport.enabled: true
```

3. **Use Secrets for credentials**:
```bash
kubectl create secret generic opensearch-credentials \
  --from-literal=username=admin \
  --from-literal=password='your-secure-password'
```

4. **Network Policies**: Restrict access to OpenSearch pods
5. **RBAC**: Configure proper roles and permissions in OpenSearch

## Monitoring

### View Logs

All pods:
```bash
kubectl logs -l app=opensearch --tail=100
```

Specific pod:
```bash
kubectl logs opensearch-0 -f
```

### Metrics

Check node stats:
```bash
curl http://localhost:9200/_nodes/stats?pretty
```

Check cluster stats:
```bash
curl http://localhost:9200/_cluster/stats?pretty
```

### Common Issues

#### Pods in Pending State

Check PVC status:
```bash
kubectl describe pvc opensearch-data-opensearch-0
```

Check EBS CSI driver:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

#### Pods CrashLoopBackOff

Check vm.max_map_count:
```bash
kubectl logs opensearch-0
```

The init container should set this, but verify on nodes:
```bash
kubectl get nodes
kubectl debug node/<node-name> -it --image=busybox
sysctl vm.max_map_count
```

#### Cluster Not Forming

Check discovery settings:
```bash
kubectl exec opensearch-0 -- curl -s localhost:9200/_cat/nodes?v
```

Check logs for discovery errors:
```bash
kubectl logs opensearch-0 | grep -i discovery
```

## Backup and Restore

### Register S3 Snapshot Repository

```bash
curl -X PUT "localhost:9200/_snapshot/s3_backup" -H 'Content-Type: application/json' -d'
{
  "type": "s3",
  "settings": {
    "bucket": "your-backup-bucket",
    "region": "us-east-1",
    "base_path": "opensearch-snapshots"
  }
}
'
```

### Create Snapshot

```bash
curl -X PUT "localhost:9200/_snapshot/s3_backup/snapshot_1?wait_for_completion=true"
```

### Restore Snapshot

```bash
curl -X POST "localhost:9200/_snapshot/s3_backup/snapshot_1/_restore"
```

## Maintenance

### Rolling Restart

Restart pods one by one:
```bash
kubectl rollout restart statefulset opensearch
```

### Update Configuration

Edit ConfigMap:
```bash
kubectl edit configmap opensearch-config
```

Then restart pods:
```bash
kubectl rollout restart statefulset opensearch
```

### Drain a Node

```bash
# Disable shard allocation
curl -X PUT "localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}
'

# Stop pod
kubectl delete pod opensearch-0

# Re-enable shard allocation
curl -X PUT "localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}
'
```

## Cleanup

### Delete StatefulSet (Keep Data)

```bash
kubectl delete statefulset opensearch
kubectl delete svc opensearch opensearch-cluster
kubectl delete configmap opensearch-config
```

PVCs and data remain.

### Delete Everything

```bash
kubectl delete -f opensearch-statefulset.yaml
kubectl delete pvc opensearch-data-opensearch-0
kubectl delete pvc opensearch-data-opensearch-1
kubectl delete pvc opensearch-data-opensearch-2
```

### Delete EBS Volumes

The volumes will be retained due to the StorageClass reclaim policy. Delete manually:
```bash
aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/created-for/pvc/name,Values=opensearch-data-*"

aws ec2 delete-volume --volume-id vol-xxxxxx
```

## Cost Optimization

### Storage Costs

- GP3 volumes: ~$0.08/GB/month
- 3 pods × 50GB = 150GB = ~$12/month for storage
- IOPS and throughput included in GP3 pricing

### Compute Costs

Based on resource requests, ensure nodes are appropriately sized:
- Each pod needs: 1 CPU core, 3GB RAM minimum
- 3 pods need: 3 CPU cores, 9GB RAM minimum

### Optimization Tips

1. **Use Spot Instances** for non-critical environments
2. **Enable volume expansion** to start small and grow as needed
3. **Monitor actual usage** and adjust resource requests/limits
4. **Use lifecycle policies** for EBS snapshots
5. **Consider regional costs** when choosing AWS region

## Performance Tuning

### JVM Heap Size

Set to 50% of container memory:
```yaml
env:
- name: OPENSEARCH_JAVA_OPTS
  value: "-Xms4g -Xmx4g"  # For 8GB pods
```

### Index Settings

Optimize for write performance:
```bash
curl -X PUT "localhost:9200/my-index/_settings" -H 'Content-Type: application/json' -d'
{
  "index": {
    "refresh_interval": "30s",
    "number_of_replicas": 1
  }
}
'
```

### EBS Volume Performance

For high-performance workloads, use io2:
```yaml
parameters:
  type: io2
  iops: "10000"
```

## Additional Resources

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [AWS EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [OpenSearch Security Plugin](https://opensearch.org/docs/latest/security-plugin/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
