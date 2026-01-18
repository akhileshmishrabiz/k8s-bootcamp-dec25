# EKS Deployment Exercise

## Overview
This exercise covers deploying a three-tier application (frontend, backend, and database) on Amazon EKS using Terraform and Kubernetes manifests. You'll learn infrastructure as code, Kubernetes deployments, and production-ready DevOps practices.

## Prerequisites
- AWS Account with appropriate permissions
- Terraform 1.8.1 installed
- kubectl configured
- Docker installed
- Basic understanding of Kubernetes and Terraform

---

## Part 1: Infrastructure Setup

### Exercise 1.1: Deploy EKS Cluster
**Objective:** Create an EKS cluster with VPC networking

**Tasks:**
1. Navigate to `eks/infra/` directory
2. Review the `network.tf` file - understand VPC, subnets, and NAT gateway configuration
3. Review `eks.tf` - understand cluster configuration with managed node groups
4. Initialize Terraform: `terraform init`
5. Deploy infrastructure: `terraform apply`
6. Configure kubectl to connect to your cluster:
   ```bash
   aws eks update-kubeconfig --region ap-south-1 --name eks-cluster-5-3rdjan
   ```
7. Verify cluster access: `kubectl get nodes`

**Expected Outcome:** 
- Functional EKS cluster with 2 worker nodes
- VPC with public and private subnets
- NAT gateway for private subnet internet access

---

### Exercise 1.2: Deploy AWS Load Balancer Controller
**Objective:** Install the load balancer controller using Helm via Terraform

**Tasks:**
1. Review `iam.tf` - understand IAM role and policy for IRSA (IAM Roles for Service Accounts)
2. Review `load-balancer-controller.tf` - understand Helm chart deployment
3. Verify OIDC provider is automatically created by the EKS module
4. After cluster deployment, verify load balancer controller installation:
   ```bash
   kubectl get deployment -n kube-system aws-load-balancer-controller
   kubectl get pods -n kube-system | grep aws-load-balancer-controller
   ```

**Expected Outcome:**
- Load balancer controller running in kube-system namespace
- Service account with proper IAM role annotations

---

## Part 2: Application Infrastructure

### Exercise 2.1: Create ECR Repositories
**Objective:** Set up container registries for backend and frontend images

**Tasks:**
1. Navigate to `class8/infra/` directory
2. Review `ecr.tf` - understand repository configuration
3. Initialize and apply: `terraform init && terraform apply`
4. Note the repository URIs for later use
5. Authenticate Docker to ECR:
   ```bash
   aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-south-1.amazonaws.com
   ```

**Expected Outcome:**
- Two ECR repositories: `devopsdozo-backend` and `devopsdozo-frontend`

---

### Exercise 2.2: Deploy RDS Database
**Objective:** Create PostgreSQL database for the application

**Tasks:**
1. Review `rds.tf` - understand:
   - Database subnet group creation
   - Security group with port 5432 access
   - KMS encryption for database and secrets
   - Password generation using `random_password`
2. Review `variables.tf` for database default settings
3. Apply changes: `terraform apply -target=aws_db_instance.postgres`
4. Verify database creation in AWS Console
5. Check Secrets Manager for database credentials

**Expected Outcome:**
- PostgreSQL RDS instance running in private subnets
- Database credentials stored in AWS Secrets Manager
- KMS key for encryption

---

### Exercise 2.3: Create Kubernetes Resources
**Objective:** Set up namespace, secrets, and ConfigMaps

**Tasks:**
1. Review `k8s.tf`:
   - Namespace creation
   - Secret with database URL and credentials
   - ConfigMap with database connection details
   - External service for database DNS resolution
2. Apply: `terraform apply`
3. Verify resources:
   ```bash
   kubectl get namespace devopsdozo
   kubectl get secrets -n devopsdozo
   kubectl get configmap -n devopsdozo
   kubectl get service -n devopsdozo
   ```
4. Test DNS resolution from within cluster:
   ```bash
   kubectl run -it --rm dns-test --image=busybox --restart=Never -- nslookup devopsdozo-db-service.devopsdozo.svc.cluster.local
   ```

**Expected Outcome:**
- Namespace `devopsdozo` created
- Database secrets and config available to pods
- External service resolving to RDS endpoint

---

## Part 3: Application Deployment

### Exercise 3.1: Build and Push Container Images
**Objective:** Build Docker images and push to ECR

**Tasks:**
1. Navigate to `class8/backend/` directory
2. Build backend image:
   ```bash
   docker build -t devopsdozo-backend .
   docker tag devopsdozo-backend:latest <account-id>.dkr.ecr.ap-south-1.amazonaws.com/devopsdozo-backend:latest
   docker push <account-id>.dkr.ecr.ap-south-1.amazonaws.com/devopsdozo-backend:latest
   ```
3. Navigate to `class8/frontend/` directory
4. Build frontend image:
   ```bash
   docker build -t devopsdozo-frontend .
   docker tag devopsdozo-frontend:latest <account-id>.dkr.ecr.ap-south-1.amazonaws.com/devopsdozo-frontend:latest
   docker push <account-id>.dkr.ecr.ap-south-1.amazonaws.com/devopsdozo-frontend:latest
   ```

**Expected Outcome:**
- Backend and frontend images in ECR
- Latest tags applied to both images

---

### Exercise 3.2: Run Database Migration
**Objective:** Initialize database schema before backend deployment

**Tasks:**
1. Review `class8/k8s/migration-job.yaml`:
   - Understand Job vs Deployment
   - Note init container pattern for database connectivity check
   - Review environment variables from secrets and ConfigMaps
2. Update image URI in the migration job YAML
3. Deploy migration job:
   ```bash
   kubectl apply -f class8/k8s/migration-job.yaml
   ```
4. Monitor job completion:
   ```bash
   kubectl get jobs -n devopsdozo
   kubectl logs -n devopsdozo job/dvopsdozo-migration
   ```
5. Verify database tables were created (use psql or pgAdmin)

**Expected Outcome:**
- Migration job completes successfully
- Database tables created
- Job pod removed after TTL (100 seconds)

---

### Exercise 3.3: Deploy Backend Application
**Objective:** Deploy Flask API backend

**Tasks:**
1. Review `class8/k8s/backend.yaml`:
   - Deployment with 2 replicas
   - Init container for database readiness check
   - Environment variables from secrets and ConfigMaps
   - Resource requests and limits
   - ClusterIP service on port 8000
2. Update image URI in the YAML
3. Deploy backend:
   ```bash
   kubectl apply -f class8/k8s/backend.yaml
   ```
4. Verify deployment:
   ```bash
   kubectl get deployment -n devopsdozo backend
   kubectl get pods -n devopsdozo -l app=backend
   kubectl logs -n devopsdozo -l app=backend
   ```
5. Test backend service:
   ```bash
   kubectl port-forward -n devopsdozo service/backend 8000:8000
   ```
   Visit `http://localhost:8000` in browser

**Expected Outcome:**
- 2 backend pods running
- Backend accessible via ClusterIP service
- Application successfully connected to database

---

### Exercise 3.4: Deploy Frontend Application
**Objective:** Deploy React frontend

**Tasks:**
1. Review `class8/k8s/frontend.yaml`:
   - Deployment with 2 replicas
   - BACKEND_URL environment variable pointing to internal service
   - Readiness and liveness probes
   - ClusterIP service on port 80
2. Update image URI in the YAML
3. Deploy frontend:
   ```bash
   kubectl apply -f class8/k8s/frontend.yaml
   ```
4. Verify deployment:
   ```bash
   kubectl get deployment -n devopsdozo frontend
   kubectl get pods -n devopsdozo -l app=frontend
   ```
5. Test frontend service:
   ```bash
   kubectl port-forward -n devopsdozo service/frontend 3000:80
   ```
   Visit `http://localhost:3000` in browser

**Expected Outcome:**
- 2 frontend pods running
- Frontend successfully communicating with backend
- Application functioning end-to-end

---

## Part 4: Ingress and DNS Setup

### Exercise 4.1: Configure Route53 and ACM Certificate
**Objective:** Set up domain and SSL certificate

**Tasks:**
1. Review `class8/infra/rout53.tf`:
   - Imported hosted zone for your domain
   - ACM certificate creation with DNS validation
   - Route53 record for certificate validation
   - A record pointing to ALB (created by ingress)
2. Update `domain_name` in the certificate resource to match your domain
3. Apply infrastructure:
   ```bash
   terraform apply
   ```
4. Wait for certificate validation (check ACM console)
5. Verify certificate status: `aws acm describe-certificate --certificate-arn <arn>`

**Expected Outcome:**
- ACM certificate issued and validated
- DNS validation record in Route53

---

### Exercise 4.2: Deploy Ingress with HTTPS
**Objective:** Create Application Load Balancer with SSL termination

**Tasks:**
1. Review `class8/infra/k8s.tf` ingress section:
   - ALB annotations for internet-facing load balancer
   - SSL redirect configuration
   - Certificate ARN annotation
   - Path-based routing (/ to frontend, /api to backend)
2. Ingress is already in terraform - apply if not done:
   ```bash
   terraform apply
   ```
3. Wait for ALB creation (5-10 minutes)
4. Verify ingress:
   ```bash
   kubectl get ingress -n devopsdozo
   kubectl describe ingress -n devopsdozo devopsdozo-ingress
   ```
5. Check ALB in AWS Console:
   - Target groups are healthy
   - Listeners configured for HTTP (80) and HTTPS (443)
   - SSL certificate attached

**Expected Outcome:**
- ALB created with HTTPS listener
- HTTP automatically redirects to HTTPS
- Target groups registered with backend/frontend pods

---

### Exercise 4.3: Verify End-to-End Application
**Objective:** Test the complete application via public domain

**Tasks:**
1. Wait for Route53 DNS propagation (may take a few minutes)
2. Visit your application: `https://devopsdozo.akhileshmishra.tech`
3. Test functionality:
   - View quiz questions
   - Submit answers
   - Upload new questions (CSV files)
4. Verify HTTPS:
   - Check for valid SSL certificate
   - Confirm HTTP redirects to HTTPS
5. Test backend API directly: `https://devopsdozo.akhileshmishra.tech/api/`
6. Monitor application:
   ```bash
   kubectl get pods -n devopsdozo -w
   kubectl top pods -n devopsdozo
   ```

**Expected Outcome:**
- Application accessible via public HTTPS URL
- All features working correctly
- Secure connection with valid SSL certificate

---

## Part 5: Advanced Exercises (Optional)

### Exercise 5.1: Implement Fargate Profile
**Objective:** Deploy nginx to Fargate

**Tasks:**
1. Review `class8/infra/fargate.tf`
2. Understand pod execution role for Fargate
3. Note selector configuration for namespace-based scheduling
4. Verify nginx deployment runs on Fargate nodes

---

### Exercise 5.2: Terraform State Management
**Objective:** Migrate local state to S3 backend

**Tasks:**
1. Create S3 bucket for state storage
2. Update `versions.tf` with backend configuration
3. Run `terraform init -migrate-state`
4. Verify state file in S3
5. Enable versioning on S3 bucket

---

### Exercise 5.3: Import Existing Resources
**Objective:** Bring manually created resources under Terraform management

**Tasks:**
1. Create an ECR repository manually in AWS Console
2. Write Terraform configuration for it
3. Use `terraform import` to bring it under management
4. Verify with `terraform plan` (should show no changes)

---

## Cleanup

**Important:** To avoid AWS charges, destroy resources when done:

```bash
# Delete Kubernetes resources first
kubectl delete -f class8/k8s/

# Destroy application infrastructure
cd class8/infra
terraform destroy

# Destroy EKS cluster
cd ../../eks/infra
terraform destroy
```

---

## Key Concepts Learned

1. **Infrastructure as Code:** Managing AWS resources with Terraform
2. **EKS Architecture:** Control plane, worker nodes, VPC networking
3. **Kubernetes Resources:** Deployments, Services, ConfigMaps, Secrets, Jobs
4. **Container Registry:** Building and managing Docker images in ECR
5. **Database Management:** RDS deployment, secrets management, migrations
6. **Service Discovery:** Internal DNS, ExternalName services
7. **Ingress Controllers:** ALB integration with Kubernetes
8. **SSL/TLS:** Certificate management with ACM
9. **DNS Management:** Route53 integration
10. **Security:** IAM roles, IRSA, KMS encryption

---

## Troubleshooting Tips

- **Pods not starting:** Check `kubectl describe pod <pod-name> -n devopsdozo`
- **Database connection issues:** Verify security groups allow port 5432
- **Ingress not creating ALB:** Check load balancer controller logs
- **Certificate validation stuck:** Verify DNS records in Route53
- **Images not pulling:** Ensure ECR authentication is valid
- **State file conflicts:** Use S3 backend with DynamoDB locking

---

## Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
