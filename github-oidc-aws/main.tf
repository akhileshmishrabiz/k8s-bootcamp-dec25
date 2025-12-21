
# create IAM inentity provider for github -> aws IAM 
# create iam policy that allow users to talkk to ecr 
# iam role that allow the web idnity to assukme this role 
# and attach the iam policy for ecr to this role. 
# on github -> use that role instead of keys


resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Name = "GitHub-Actions-OIDC-Provider"
  }
}

resource "aws_iam_role" "github_actions_eks_build_role" {
  name = "eks-github-actions-build-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
                "repo:akhileshmishrabiz/k8s-bootcamp-dec25:main"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "GitHub-Actions-EKS-Deploy-Role"
  }
}

resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
    role       = aws_iam_role.github_actions_eks_build_role.name
    policy_arn = aws_iam_policy.ecr_policy.arn
}