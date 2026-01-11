import {
  to = aws_ecr_repository.manualcreatedrepo
  id = "demo"
}   

import {
  to = aws_ecr_repository.manualcreatedrepo1
  id = "ecs-studentportal"
}   




# terraform plan -generate-config-out=generated_resources.tf
