# things to do

- Build a ci for app build
- deploy app on eks and do rolling upgrade for new version u[date]
- build cd for automated rolling upgrade(legacy but important to understand why we need gitops)
- HPA




EKS cluster build step
- build eks cluster from console
- use clauster iam role 
- vpc cni, kube proxy and core dns plugins and create cluster
- register clusetr on local - auth and all
- kubectl context management 
- managed nodes confif 


aws eks update-kubeconfig --region ap-south-1 --name demo-akhilesh


kubectl port-forward -n student-portal service/student-portal 8111:8080 


new image: 879381241087.dkr.ecr.ap-south-1.amazonaws.com studentportal:c6ca170049d679e4b6081bdcfd1536bf51904e0e

kubectl set image deployment/student-portal -n student-portal flask=879381241087.dkr.ecr.ap-south-1.amazonaws.com/studentportal:c6ca170049d679e4b6081bdcfd1536bf51904e0e

kubectl set image deployment/student-portal -n student-portal flask=nginx:latest

kubectl rollout restart deployment/student-portal -n student-portal 
