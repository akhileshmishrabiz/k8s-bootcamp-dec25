resource "aws_ecr_repository" "frontend" {
    name                 = "eks-3-tier-frontend"
    image_tag_mutability = "MUTABLE"


    tags = {
        Name = "frontend-repo"
    }
}

resource "aws_ecr_repository" "backend" {
    name                 = "eks-3-tier-backend"
    image_tag_mutability = "MUTABLE"


    tags = {
        Name = "backend-repo"
    }
}

output "frontend_repository_url" {
    value       = aws_ecr_repository.frontend.repository_url
    description = "The URL of the frontend ECR repository"
}

output "backend_repository_url" {
    value       = aws_ecr_repository.backend.repository_url
    description = "The URL of the backend ECR repository"
}