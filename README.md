# k8s-bootcamp-dec25
# dns check
kubectl run -it --rm --restart=Never dns-test --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 \
 -- dig devopsdozo-db-service.devopsdozo.svc.cluster.local 


 # db test