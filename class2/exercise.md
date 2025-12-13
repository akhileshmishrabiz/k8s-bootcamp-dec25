Part 1: Database Setup (AWS RDS)
Task 1.1: Create RDS PostgreSQL Instance
Instructions:

Go to AWS Console → RDS → Create Database
Configuration:

Engine: PostgreSQL (choose second latest version, not latest)
Template: Free tier
DB Instance Identifier: student-portal-db
Master Username: myadmin
Master Password: [Choose a password]
Storage: 20 GB with autoscaling disabled
Important: Set "Public accessibility" to YES (for this lab only)
Security Group: Allow port 5432
Default database name: Will use postgres (default)


Wait for database to be in "Available" state (~5 minutes)
Document the following from RDS console:

Endpoint hostname
Port (should be 5432)
Database name (postgres)
Username and password



Expected Output: RDS instance running and accessible

Part 2: Container Image Preparation
Task 2.1: Build and Push Docker Image to ECR
Instructions:

Create ECR repository:

bashaws ecr create-repository --repository-name studentportal --region ap-south-1

Build the Docker image:

bashcd app/
docker build -t studentportal:1.0 .

Tag the image for ECR:

bashdocker tag studentportal:1.0 <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/studentportal:1.0

Authenticate to ECR:

bashaws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

Push the image:

bashdocker push <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/studentportal:1.0

Load image into Minikube (for local testing):

bashminikube image load studentportal:1.0
Expected Output: Image successfully pushed to ECR and loaded in Minikube

Part 3: Kubernetes Configuration
Task 3.1: Create Namespace
Instructions:

Create file: k8s/namespace.yaml

yamlapiVersion: v1
kind: Namespace
metadata:
  name: student-portal

Apply the namespace:

bashkubectl apply -f k8s/namespace.yaml

Verify:

bashkubectl get namespaces
```

**Expected Output:** Namespace `student-portal` created

---

### Task 3.2: Create Database Connection String Secret

**Instructions:**

1. Build your database link in this format:
```
postgresql://USERNAME:PASSWORD@ENDPOINT:5432/postgres
```
Example:
```
postgresql://myadmin:MyPassword123@student-portal-db.xxxxx.ap-south-1.rds.amazonaws.com:5432/postgres

Encode the database link:

bashecho -n "postgresql://myadmin:PASSWORD@ENDPOINT:5432/postgres" | base64

Create file: k8s/secret.yaml

yamlapiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: student-portal
type: Opaque
data:
  DATABASE_URL: <YOUR_BASE64_ENCODED_STRING>

Apply the secret:

bashkubectl apply -f k8s/secret.yaml

Verify:

bashkubectl get secrets -n student-portal
kubectl describe secret db-secret -n student-portal
Expected Output: Secret db-secret created in student-portal namespace

Task 3.3: Create Deployment
Instructions:

Create file: k8s/deployment.yaml

yamlapiVersion: apps/v1
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
        imagePullPolicy: Never  # For Minikube local images
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: DATABASE_URL

Apply the deployment:

bashkubectl apply -f k8s/deployment.yaml

Monitor pod creation:

bashkubectl get pods -n student-portal -w
Expected Output: 3 pods running in student-portal namespace

Task 3.4: Create Service
Instructions:

Create file: k8s/service.yaml

yamlapiVersion: v1
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

Apply the service:

bashkubectl apply -f k8s/service.yaml

Verify:

bashkubectl get svc -n student-portal
Expected Output: Service student-portal-service created with ClusterIP

Part 4: Troubleshooting Exercise
Task 4.1: Common Error Scenarios
Scenario 1: ImagePullBackOff Error

Intentionally cause the error by using wrong image name in deployment
Identify the error:

bashkubectl get pods -n student-portal
kubectl describe pod <POD_NAME> -n student-portal

Document:

What error message did you see?
Where did you find it (describe output events section)?
How would you fix it?



Scenario 2: CrashLoopBackOff Error

Delete the secret to cause this error:

bashkubectl delete secret db-secret -n student-portal

Identify the issue:

bashkubectl get pods -n student-portal
kubectl logs <POD_NAME> -n student-portal
kubectl describe pod <POD_NAME> -n student-portal

Document:

What error did you see in logs?
What was the root cause?
How did you fix it?



Scenario 3: Secret Not Found

Create secret in wrong namespace (default instead of student-portal)
Observe pod status and error messages
Document the troubleshooting steps

Expected Output: Document all errors, their causes, and solutions

Part 5: Verification and Testing
Task 5.1: Test Application Connectivity
Instructions:

Check pod logs to verify database connection:

bashkubectl logs <POD_NAME> -n student-portal

Execute into a pod:

bashkubectl exec -it <POD_NAME> -n student-portal -- /bin/sh

Inside the pod, verify environment variable:

bashecho $DATABASE_URL

Test service connectivity from inside Minikube:

bashminikube ssh
curl http://<SERVICE_CLUSTER_IP>:8080
Expected Output:

Pods showing healthy logs
Environment variable correctly set
Application responding to HTTP requests


Part 6: Freelens/K9s Exploration (Optional)
Task 6.1: Install and Configure Freelens
Instructions:

Download and install Freelens from: https://freelens.com/
Freelens will automatically detect your ~/.kube/config
Navigate through the UI:

View namespaces
Inspect pods in student-portal namespace
View secrets (observe how they're displayed)
Check logs from UI
Describe resources


Document 5 tasks you can do in Freelens that are easier than CLI

Expected Output: Screenshot of Freelens showing your cluster resources

Part 7: Documentation Assignment
Task 7.1: Create RDS Strategy Document
Instructions:
Create a document covering:

RDS Instance Types:

Single Instance
Active-Passive (with standby)
Read Replicas
Aurora (active-active)
Serverless


For Each Type Document:

Architecture diagram
Use cases (when to use)
Pros and cons
Cost considerations
Real-world example scenario


Include:

Comparison table
Decision tree for choosing the right option



Expected Output: 2-3 page document with diagrams

Part 8: Interview Preparation Questions
Answer These Questions:

What is a Namespace in Kubernetes and why do we use it?
What's the difference between a Secret and ConfigMap? When would you use each?
Explain the base64 encoding used in Secrets. Is it secure? Why or why not?
What does imagePullPolicy: Never mean and when would you use it?
Walk me through the troubleshooting steps for these errors:

ImagePullBackOff
CrashLoopBackOff
CreateContainerConfigError


Why did we create the secret in the same namespace as the deployment?
Explain the difference between port and targetPort in a Kubernetes Service.
What is the purpose of setting RDS to "Public accessibility" and why is this bad practice in production?
How does Minikube differ from a production Kubernetes cluster?
Why do we use ECR instead of DockerHub in AWS environments?


Deliverables Checklist
Submit the following:

 All YAML files (namespace, secret, deployment, service)
 Screenshot of running pods (kubectl get pods -n student-portal)
 Screenshot of service (kubectl get svc -n student-portal)
 Troubleshooting documentation with error screenshots
 RDS strategy document with diagrams
 Interview questions answered
 (Optional) Freelens screenshots
 Notes on what you learned and challenges faced


Bonus Challenges

Configure AWS Secrets Manager integration (will be covered in next class)
Set up different resource limits for pods (CPU/Memory)
Create a NodePort service and access the application from your browser
Implement liveness and readiness probes
Scale the deployment to 5 replicas and observe the behavior


Resources

Kubernetes Documentation: https://kubernetes.io/docs/
AWS RDS Documentation: https://docs.aws.amazon.com/rds/
Minikube Documentation: https://minikube.sigs.k8s.io/docs/
Repository code: [Insert link]


Troubleshooting Tips

Pods not starting: Check events with kubectl describe pod
Can't connect to RDS: Verify security group allows port 5432
Secret issues: Ensure secret is in correct namespace
Image pull issues: For Minikube, use imagePullPolicy: Never for local images
Database connection fails: Verify DATABASE_URL format and credentials
