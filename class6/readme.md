# add kube config o local 

 aws eks update-kubeconfig --name eks-cluster-5-3rdjan
 
kubectl config current-context
kubectl config rename-context arn:aws:eks:ap-south-1:879381241087:cluster/eks-cluster-5-3rdjan  class5
kubectl config current-context


# how to run workload on fargate
- cretae a namespace on clutser
- create fargate profile and provide the namespace
- run the pod on that name space



# 2-tier app on aws


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
  --set clusterName=eks-cluster-5-3rdjan \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set vpcId=vpc-059f2be68bb04d92a \
  --set region=ap-south-1
