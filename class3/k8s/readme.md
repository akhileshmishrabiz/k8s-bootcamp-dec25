kubectl -n student-portal create secret docker-registry ecr-registry-secret \
  --docker-server=879381241087.dkr.ecr.ap-south-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-south-1) \
  --docker-email=livingdevops@gmail.com


postgresql://myadmin:Admin123@student-portal.cvik8accw2tk.ap-south-1.rds.amazonaws.com:5432/postgres


❯ kubectl run debug-pod --rm -it --image=postgres:16 -- bash

PGPASSWORD=Admin123 psql -h \
student-portal.cvik8accw2tk.ap-south-1.rds.amazonaws.com -U myadmin -d postgres


❯ kubectl port-forward -n student-portal service/student-portal 8080:8080
