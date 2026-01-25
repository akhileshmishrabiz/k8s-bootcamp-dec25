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


# [id=prod-craftica-frontend]
# [id=prod-craftica-catalogue]
# [id=prod-craftica-voting]
# [id=prod-craftica-recco]