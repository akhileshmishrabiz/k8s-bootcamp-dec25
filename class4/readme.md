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



######. class 5 stuff goes here ###

## IRSA for k8s to create the load balancer 
- create the iam identity provider for you cluster
- download the iam policy

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

- copy the arn for oidc id provider 

arn:aws:iam::879381241087:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/BAF6AF3D227043D5C3AA23E5E39C72EB

-> 
export cluster_name=demo-akhilesh
oidc_id=$(aws eks describe-cluster --name $cluster_name \
--query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

echo $oidc_id


# Check if IAM OIDC provider with your cluster’s issuer ID 
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4


use the above to cretae an iam role 

# create service account

# cretae iam policy with the jsn config file

```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

# cretae iam role with trust policy

```bash
aws iam create-role --role-name AWSLoadBalancerControllerRole \
    --assume-role-policy-document file://trust-policy.json
```


# attach the policy to role

```bash
aws iam attach-role-policy \
    --role-name AWSLoadBalancerControllerRole \
    --policy-arn arn:aws:iam::879381241087:policy/AWSLoadBalancerControllerIAMPolicy

```


## load balancer controller imnstall

## helm install
brew install helm (or the one for your os)

## helm repo add

helm repo add eks https://aws.github.io/eks-charts

## helm update

helm repo update

<!-- ## create a custom resource 

kubectl apply -k  \
"github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master" -->
# instal aws load balancer controller 

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=demo-akhilesh \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set vpcId=vpc-0b9dbc4b7574faa5e  \
  --set region=ap-south-1



  public subnet need tag

  Key=kubernetes.io/role/elb,Value=1


  aws ec2 describe-subnets --filters "Name=vpc-id,Values=	
vpc-0b9dbc4b7574faa5e" "Name=map-public-ip-on-launch,Values=true" \
--query "Subnets[*].{SubnetId:SubnetId,AvailabilityZone:AvailabilityZone,PublicIp:MapPublicIpOnLaunch}"

- AvailabilityZone: ap-south-1b
  PublicIp: true
  SubnetId: subnet-0bff6e900da51e8d9
- AvailabilityZone: ap-south-1a
  PublicIp: true
  SubnetId: subnet-0fe851cbd12dc1edb
- AvailabilityZone: ap-south-1c
  PublicIp: true
  SubnetId: subnet-0243c0bd813e40632
(END)


aws ec2 create-tags --resources subnet-0bff6e900da51e8d9 subnet-0fe851cbd12dc1edb \
subnet-0243c0bd813e40632 --tags Key=kubernetes.io/role/elb,Value=1

aws ec2 describe-subnets --subnet-ids subnet-0bff6e900da51e8d9 subnet-0fe851cbd12dc1edb \
subnet-0243c0bd813e40632 --query "Subnets[*].{SubnetId:SubnetId,Tags:Tags}"