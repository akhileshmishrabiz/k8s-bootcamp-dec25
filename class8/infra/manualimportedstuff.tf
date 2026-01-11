# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "demo"
resource "aws_ecr_repository" "manualcreatedrepo" {
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  name                 = "demo"
  region               = "ap-south-1"
  tags                 = {}
  tags_all             = {}
  encryption_configuration {
    encryption_type = "AES256"
    kms_key         = null
  }
  image_scanning_configuration {
    scan_on_push = false
  }
}

# __generated__ by Terraform from "ecs-studentportal"
resource "aws_ecr_repository" "manualcreatedrepo1" {
  force_delete         = null
  image_tag_mutability = "MUTABLE"
  name                 = "ecs-studentportal"
  region               = "ap-south-1"
  tags                 = {}
  tags_all             = {}
  encryption_configuration {
    encryption_type = "AES256"
    kms_key         = null
  }
  image_scanning_configuration {
    scan_on_push = false
  }
}