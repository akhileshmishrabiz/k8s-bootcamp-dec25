# Kubernetes Hands-On Lab Exercise

## Objective
This lab will help you practice the core Kubernetes concepts covered in class: Pods, Deployments, Services, and basic kubectl commands.

---

## Prerequisites
- GitHub account
- GitHub Codespaces setup (or local minikube installation)
- Basic understanding of containers and YAML

---

## Lab Setup

### Step 1: Create GitHub Codespace
1. Go to `github.com/codespaces`
2. Create a new repository called `kubernetes-lab`
3. Choose the repository and create a Codespace
4. Select **2 cores minimum**
5. Wait for VS Code to open in browser

### Step 2: Install Minikube
Run these commands in the terminal:

```bash
# Download and install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Download and install minikube
# https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start minikube
minikube start
```

### Step 3: Verify Installation
```bash
# Check minikube status
minikube status

# Check kubectl is working
kubectl get nodes

# You should see one node called 'minikube' with status 'Ready'
```

---

## Exercise 1: Working with Pods

### Task 1.1: Create a Simple Pod
Create a file called `nginx-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    tier: frontend
spec:
  containers:
  - name: nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
```

**Commands to run:**
```bash
# Create the pod
kubectl apply -f nginx-pod.yaml

# Verify pod is running
kubectl get pods

# Get detailed information
kubectl get pods -o wide

# Describe the pod to see events
kubectl describe pod nginx-pod

# Check logs (should be empty for nginx)
kubectl logs nginx-pod
```

### Task 1.2: Access the Pod
```bash
# Get pod IP
kubectl get pod nginx-pod -o wide

# Access the pod from inside minikube
minikube ssh
# Inside minikube VM, run:
curl <POD_IP>:80
# You should see nginx welcome page
exit
```

### Task 1.3: Delete and Observe
```bash
# Delete the pod
kubectl delete pod nginx-pod

# Try to get pods again
kubectl get pods
# Notice: Pod is gone and doesn't come back automatically
```

**Question:** Why didn't the pod restart automatically?

---

## Exercise 2: Working with Deployments

### Task 2.1: Create a Deployment
Create a file called `nginx-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

**Commands to run:**
```bash
# Create deployment
kubectl apply -f nginx-deployment.yaml

# Check deployment
kubectl get deployments

# Check pods created by deployment
kubectl get pods

# Get more details
kubectl get pods -o wide
```

### Task 2.2: Test Self-Healing
```bash
# Copy one pod name from the list
kubectl get pods

# Delete one pod
kubectl delete pod <POD_NAME>

# Immediately check pods again
kubectl get pods

# Notice: A new pod is automatically created!
# Check the AGE column to see the new pod
```

**Question:** What component is responsible for recreating the pod?

### Task 2.3: Scale the Deployment
```bash
# Scale up to 5 replicas
kubectl scale deployment nginx-deployment --replicas=5

# Check pods
kubectl get pods

# Scale down to 2 replicas
kubectl scale deployment nginx-deployment --replicas=2

# Check pods again
kubectl get pods

# Notice how pods are terminated
```

### Task 2.4: Update the Deployment
Modify `nginx-deployment.yaml` to change replicas to 4:
```yaml
spec:
  replicas: 4
```

```bash
# Apply the changes
kubectl apply -f nginx-deployment.yaml

# Verify
kubectl get pods
```

---

## Exercise 3: Working with Services

### Task 3.1: Create a ClusterIP Service
Create a file called `nginx-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

**Commands to run:**
```bash
# Create the service
kubectl apply -f nginx-service.yaml

# Check services
kubectl get services
# or
kubectl get svc

# Get detailed info
kubectl get svc -o wide

# Describe the service
kubectl describe svc nginx-service
```

### Task 3.2: Verify Service Endpoints
```bash
# Check endpoints (should show all pod IPs)
kubectl get endpoints nginx-service

# Compare with pod IPs
kubectl get pods -o wide

# They should match!
```

### Task 3.3: Access via Service
```bash
# Get service IP
kubectl get svc nginx-service

# Access from inside minikube
minikube ssh
# Inside minikube, run:
curl <SERVICE_IP>:80
# You should see nginx welcome page
exit
```

### Task 3.4: Test Load Balancing
```bash
# SSH into minikube
minikube ssh

# Make multiple requests to see load balancing
for i in {1..10}; do curl -s <SERVICE_IP>:80 | grep title; done

exit
```

---

## Exercise 4: Labels and Selectors

### Task 4.1: Verify Label Matching
```bash
# Check deployment labels
kubectl get deployment nginx-deployment -o yaml | grep -A 5 selector

# Check pod labels
kubectl get pods --show-labels

# Check service selector
kubectl get svc nginx-service -o yaml | grep -A 3 selector
```

### Task 4.2: Break and Fix the Service
Edit `nginx-service.yaml` and change the selector:
```yaml
selector:
  app: wrong-label  # This won't match any pods
```

```bash
# Apply the broken service
kubectl apply -f nginx-service.yaml

# Check endpoints
kubectl get endpoints nginx-service
# Notice: No endpoints!

# Fix it back
# Edit nginx-service.yaml and change back to:
# app: nginx

kubectl apply -f nginx-service.yaml

# Check endpoints again
kubectl get endpoints nginx-service
# Endpoints are back!
```

---

## Exercise 5: Troubleshooting Practice

### Task 5.1: Create a Broken Pod
Create `broken-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod
spec:
  containers:
  - name: nginx
    image: nginx:nonexistent-tag
    ports:
    - containerPort: 80
```

```bash
# Try to create it
kubectl apply -f broken-pod.yaml

# Check status
kubectl get pods

# Describe to see what's wrong
kubectl describe pod broken-pod

# Look for the error in Events section
```

**Question:** What is the error? How would you fix it?

### Task 5.2: Check Resource Usage
```bash
# Check node resources
kubectl top node

# Check pod resources (may need metrics-server)
kubectl top pods
```

---

## Exercise 6: Complete Application Stack

### Task 6.1: Deploy a Multi-Tier Application
Create `webapp-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
      tier: frontend
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
    spec:
      containers:
      - name: webapp
        image: httpd:latest
        ports:
        - containerPort: 80
```

Create `webapp-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: ClusterIP
  selector:
    app: webapp
    tier: frontend
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
```

```bash
# Deploy everything
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml

# Verify all resources
kubectl get all

# Test the service
minikube ssh
curl <SERVICE_IP>:8080
exit
```

---

## Exercise 7: Cleanup and Exploration

### Task 7.1: Clean Up Resources
```bash
# Delete specific resources
kubectl delete deployment nginx-deployment
kubectl delete deployment webapp
kubectl delete service nginx-service
kubectl delete service webapp-service

# Or delete everything at once
kubectl delete all --all

# Verify cleanup
kubectl get all
```

### Task 7.2: Explore Kubernetes Objects
```bash
# See all API resources
kubectl api-resources

# Get cluster info
kubectl cluster-info

# Check component status
kubectl get componentstatuses
```

---

## Challenge Exercises

### Challenge 1: Redis Deployment
Create a deployment for Redis with:
- 1 replica
- Image: `redis:latest`
- Port: 6379
- Service name: `redis-service`
- Service type: ClusterIP

### Challenge 2: Multi-Container Pod
Create a pod with two containers:
1. Nginx container (port 80)
2. Busybox container running a simple command

Hint: Add another container in the containers array

### Challenge 3: Environment Variables
Modify your nginx deployment to include environment variables:
```yaml
env:
- name: MY_VAR
  value: "Hello Kubernetes"
```

Then exec into the pod and check the environment variable:
```bash
kubectl exec -it <POD_NAME> -- env | grep MY_VAR
```

---

## Research Questions (Homework)

1. **How does pod-to-pod communication work across nodes?**
   - Research the role of kube-proxy
   - Understand overlay networks
   - Write a 2-3 paragraph explanation

2. **What happens when you run `kubectl apply`?**
   - Trace the request through API server → Controller Manager → Scheduler → Kubelet
   - Draw a diagram of the flow

3. **What's the difference between Deployment and ReplicaSet?**
   - When would you use one over the other?
   - Check what ReplicaSets are created by your deployment: `kubectl get rs`

4. **Service Types**
   - Research ClusterIP, NodePort, and LoadBalancer
   - What are the use cases for each?

---

## Useful Commands Reference

```bash
# Get resources
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get all

# Detailed output
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Create/Update resources
kubectl apply -f <file.yaml>
kubectl create -f <file.yaml>

# Delete resources
kubectl delete pod <pod-name>
kubectl delete -f <file.yaml>
kubectl delete all --all

# Scaling
kubectl scale deployment <name> --replicas=<number>

# Port forwarding (for local access)
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward service/<service-name> 8080:80

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- <command>

# Copy files
kubectl cp <pod-name>:/path/to/file ./local-file

# Get help
kubectl explain pods
kubectl explain deployment.spec
```

---

## Tips for Success

1. **Always check your YAML indentation** - YAML is sensitive to spaces
2. **Use `kubectl get pods -w`** to watch pods in real-time
3. **Read the Events section** in `kubectl describe` for troubleshooting
4. **Labels must match exactly** between deployments and services
5. **Start with small replicas (1-3)** when testing

---

## Next Steps

After completing this lab:
1. Practice creating your own deployments with different images
2. Experiment with different service types
3. Try deploying a real application (like a simple web app with a database)
4. Move on to learning about ConfigMaps, Secrets, and Persistent Volumes

---

## Solutions & Answers

### Exercise 1.3 Answer
The pod doesn't restart automatically because pods are ephemeral and not managed by any controller. When you delete a pod directly, it's gone forever. You need a Deployment or ReplicaSet to ensure self-healing.

### Exercise 2.2 Answer
The Controller Manager (specifically the Deployment controller) monitors the desired state (3 replicas) versus actual state. When it detects a missing pod, it instructs the Scheduler to create a new one.

### Exercise 5.1 Answer
The error is "ImagePullBackOff" - the image tag doesn't exist. Fix by changing to `image: nginx:latest` or another valid tag.

---