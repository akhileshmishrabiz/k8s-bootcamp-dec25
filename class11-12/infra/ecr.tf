# 
resource "aws_ecr_repository" "images" {
  for_each = local.services

  name                 = "${var.environment}-${var.app_name}-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = each.key
  }
}


# [id=879381241087.dkr.ecr.ap-south-1.amazonaws.com/prod-craftica-frontend]
# [id=879381241087.dkr.ecr.ap-south-1.amazonaws.com/prod-craftica-catalogue]
# [id=879381241087.dkr.ecr.ap-south-1.amazonaws.com/prod-craftica-voting]
# [id=879381241087.dkr.ecr.ap-south-1.amazonaws.com/prod-craftica-recco]


# frontend.prod.akhileshmishra.tech
# catalogue.prod.akhileshmishra.tech
# voting.prod.akhileshmishra.tech
# recco.prod.akhileshmishra.tech
# *.prod.akhileshmishra.tech