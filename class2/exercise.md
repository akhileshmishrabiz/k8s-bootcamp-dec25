# Kubernetes Two-Tier Application Lab - README

## 🎯 What You'll Build
A Flask web application connected to PostgreSQL database running on AWS RDS, deployed on Kubernetes (Minikube).

---

## 📋 Prerequisites Checklist
Before starting, make sure you have:
- ✅ Minikube installed and running (`minikube start`)
- ✅ kubectl installed
- ✅ Docker installed and running
- ✅ AWS Account with CLI configured
- ✅ Code repository cloned

---

## 🚀 Quick Start Guide

### Step 1: Create RDS Database (10 mins)
```bash
# Go to AWS Console → RDS → Create Database
```
**Settings:**
- Engine: PostgreSQL (choose 2nd latest version)
- Template: Free tier
- DB name: `student-portal-db`
- Username: `myadmin`
- Password: `[your-secure-password]`
- **IMPORTANT:** Set "Public accessibility" to YES
- Security Group: Allow port 5432

**Wait for "Available" status, then note down:**
- Endpoint: `student-portal-db.xxxxx.ap-south-1.rds.amazonaws.com`
- Port: `5432`
- Database name: `postgres`

---

### Step 2: Build Your Database Connection String
```bash
# Format:
postgresql://USERNAME:PASSWORD@ENDPOINT:5432/postgres

# Example:
postgresql://myadmin:MyPass123@student-portal-db.xxxxx.ap-south-1.rds.amazonaws.com:5432/postgres
```
**Save this string - you'll need it soon!**

---

### Step 3: Prepare Docker Image (5 mins)

#### Option A: Use Local Image (Faster for Minikube)
```bash
# Navigate to app folder
cd app/

# Build image
docker build -t studentportal:1.0 .

# Load into Minikube
minikube image load studentportal:1.0

# Verify
minikube image ls | grep studentportal
```

#### Option B: Push to ECR (Production-like)
```bash
# Create ECR repository
aws ecr create-repository --repository-name studentportal

# Build and tag
docker build -t studentportal:1.0 .
docker tag studentportal:1.0 <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/studentportal:1.0

# Login to ECR
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com

# Push
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/studentportal:1.0
```

---

### Step 4: Create Kubernetes Namespace (1 min)
```bash
# Create k8s folder if not exists
mkdir -p k8s
cd k8s

# Create namespace.yaml
cat <<EOF > namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: student-portal
EOF

# Apply
kubectl apply -f namespace.yaml

# Verify
kubectl get namespaces
```

---

### Step 5: Create Secret for Database (3 mins)
```bash
# Encode your database connection string
echo -n "postgresql://myadmin:PASSWORD@ENDPOINT:5432/postgres" | base64

# Copy the output, then create secret.yaml
cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: student-portal
type: Opaque
data:
  DATABASE_URL: <PASTE_YOUR_BASE64_STRING_HERE>
EOF

# Apply
kubectl apply -f secret.yaml

# Verify
kubectl get secrets -n student-portal
```

---

### Step 6: Deploy Application (3 mins)
```bash
# Create deployment.yaml
cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: student-portal
  namespace: student-portal
spec:
  replicas: 3
  selector:
    matchLabels:
      app: student-portal
  template:
    metadata:
      labels:
        app: student-portal
    spec:
      containers:
      - name: flask-app
        image: studentportal:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DATABASE_URL
EOF

# Apply
kubectl apply -f deployment.yaml

# Watch pods come up
kubectl get pods -n student-portal -w
# Press Ctrl+C to stop watching
```

**✅ Success looks like:**
```
NAME                              READY   STATUS    RESTARTS   AGE
student-portal-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
student-portal-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
student-portal-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

---

### Step 7: Create Service (2 mins)
```bash
# Create service.yaml
cat <<EOF > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: student-portal-service
  namespace: student-portal
spec:
  type: ClusterIP
  selector:
    app: student-portal
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8000
EOF

# Apply
kubectl apply -f service.yaml

# Verify
kubectl get svc -n student-portal
```

---

### Step 8: Test Your Application (5 mins)

#### Check Pod Status
```bash
# View all pods
kubectl get pods -n student-portal

# Check logs of first pod
kubectl logs <POD_NAME> -n student-portal

# You should see Flask app starting messages
```

#### Verify Database Connection
```bash
# Get inside a pod
kubectl exec -it <POD_NAME> -n student-portal -- /bin/sh

# Inside the pod, check environment variable
echo $DATABASE_URL

# Exit the pod
exit
```

#### Test Service
```bash
# Get service ClusterIP
kubectl get svc -n student-portal

# SSH into Minikube
minikube ssh

# Test the service (replace with your ClusterIP)
curl http://<CLUSTER_IP>:8080

# Exit Minikube
exit
```

---

## 🐛 Common Issues & Quick Fixes

### Issue 1: ImagePullBackOff
```bash
# Check the error
kubectl describe pod <POD_NAME> -n student-portal

# Common causes:
# - Image name typo
# - Image not loaded in Minikube
# - Wrong imagePullPolicy

# Fix: Reload image
minikube image load studentportal:1.0
kubectl delete pod <POD_NAME> -n student-portal
```

### Issue 2: CrashLoopBackOff
```bash
# Check logs
kubectl logs <POD_NAME> -n student-portal

# Common causes:
# - Database connection failed
# - Wrong DATABASE_URL
# - Secret not found

# Fix: Verify secret exists
kubectl get secrets -n student-portal
kubectl describe secret db-secret -n student-portal
```

### Issue 3: CreateContainerConfigError
```bash
# Check pod description
kubectl describe pod <POD_NAME> -n student-portal

# Common cause:
# - Secret in wrong namespace

# Fix: Ensure secret is in student-portal namespace
kubectl get secrets -n student-portal
# If not there, recreate secret in correct namespace
```

### Issue 4: Pods Pending
```bash
# Check what's wrong
kubectl describe pod <POD_NAME> -n student-portal

# Common causes:
# - Insufficient resources
# - Minikube not running

# Fix: Check Minikube status
minikube status
```

---

## 🛠️ Useful Commands

### View Resources
```bash
# All resources in namespace
kubectl get all -n student-portal

# Detailed pod info
kubectl describe pod <POD_NAME> -n student-portal

# Pod logs
kubectl logs <POD_NAME> -n student-portal

# Follow logs in real-time
kubectl logs -f <POD_NAME> -n student-portal

# Previous logs (if pod restarted)
kubectl logs --previous <POD_NAME> -n student-portal
```

### Debug Inside Pod
```bash
# Get shell access
kubectl exec -it <POD_NAME> -n student-portal -- /bin/sh

# Check environment variables
env

# Check specific variable
echo $DATABASE_URL

# Exit
exit
```

### Delete & Recreate
```bash
# Delete everything in namespace
kubectl delete all --all -n student-portal

# Reapply everything
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### Clean Up Everything
```bash
# Delete namespace (deletes everything inside)
kubectl delete namespace student-portal

# Delete RDS database (from AWS Console)
# Delete ECR repository (from AWS Console)
```

---

## 📊 Verification Checklist

- [ ] RDS database is "Available"
- [ ] Database connection string is correct
- [ ] Docker image built successfully
- [ ] Image loaded in Minikube
- [ ] Namespace created
- [ ] Secret created in correct namespace
- [ ] Deployment shows 3/3 pods running
- [ ] Service created with ClusterIP
- [ ] Pod logs show no errors
- [ ] DATABASE_URL environment variable is set in pods
- [ ] Application responds to HTTP requests

---

## 🎓 What You Learned

✅ Created AWS RDS PostgreSQL database  
✅ Built and managed Docker images  
✅ Created Kubernetes namespaces  
✅ Used Secrets for sensitive data  
✅ Deployed multi-replica applications  
✅ Created Services for pod communication  
✅ Troubleshot common Kubernetes errors  
✅ Used kubectl for debugging  

---

## 📚 Next Steps

1. **Install Freelens** (UI tool for Kubernetes)
2. **Learn AWS Secrets Manager integration** (better than base64 secrets)
3. **Add resource limits** (CPU/Memory)
4. **Implement health checks** (liveness/readiness probes)
5. **Try NodePort service** to access from browser

---

## 🆘 Need Help?

**Check logs first:**
```bash
kubectl logs <POD_NAME> -n student-portal
kubectl describe pod <POD_NAME> -n student-portal
```

**Common mistakes:**
- Secret in wrong namespace
- Wrong database connection string
- Forgot to load image in Minikube
- Typo in image name
- RDS security group blocking port 5432

**Still stuck?** Review the transcript or ask for help!

---

## 📝 Assignment Submission

Document these:
1. Screenshots of running pods
2. Screenshot of service
3. Errors you encountered and how you fixed them
4. What you learned

**Good luck! 🚀**