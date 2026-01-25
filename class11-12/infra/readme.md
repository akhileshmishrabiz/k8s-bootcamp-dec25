
# Dev
## Terraform init

terraform init -backend-config=vars/dev.tfbackend

terraform plan -var-file=vars/dev.tfvars

terraform apply -var-file=vars/dev.tfvars


# prod
## Terraform init

terraform init -backend-config=vars/prod.tfbackend


terraform plan -var-file=vars/prod.tfvars

terraform apply -var-file=vars/prod.tfvars



# conect to eks cluster from local

aws eks update-kubeconfig --name prod-dec-ekscluster 
