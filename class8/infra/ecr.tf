resource "aws_ecr_repository" "backend" {
    name                 = "${var.app_name}-backend"
    image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "frontend" {
    name                 = "${var.app_name}-frontend"
    image_tag_mutability = "MUTABLE"

}

# output "repo1_url" {
#     value = aws_ecr_repository.repo1.repository_url
# }

# output "repo2_url" {
#     value = aws_ecr_repository.repo2.repository_url
# }