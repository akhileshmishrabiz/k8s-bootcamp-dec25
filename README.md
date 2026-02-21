# k8s-bootcamp-dec25
# dns check
kubectl run -it --rm --restart=Never dns-test --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 \
 -- dig devopsdozo-db-service.devopsdozo.svc.cluster.local 


 # db test


postgresql://postgres:3drFnRM8D9@bootcampclass5-dev-devopsdozo.cvik8accw2tk.ap-south-1.rds.amazonaws.com:5432/postgres 
 psql -h bootcampclass5-dev-devopsdozo.cvik8accw2tk.ap-south-1.rds.amazonaws.com -d postgres -U postgres




 api_key_dummy="asdfghjksfqwfweqfsffsfsf"