resource "aws_iam_role" "ecsTaskExecutionRole" {
  name                = "${var.project}-${var.environment}-execution-task-role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    Name        = "${var.project}-${var.environment}-iam-ecsTaskExecutionRole-role"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_policy" "ecr_pullthroughcache_policy" {
  name        = "${var.project}-${var.environment}-ecr-pullthrough-policy"
  description = "Policy to allow ECS task execution role to interact with ECR pull-through cache"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages"
        ],
        Resource = "arn:aws:ecr:eu-central-1:762233757243:repository/quay/keycloak/*"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-ecr-pullthrough-policy"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionPolicy_AmazonEC2ContainerServiceforEC2Role" {
  role        = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionPolicy_AmazonECSTaskExecutionRolePolicy" {
  role        = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionPolicy_AWSServiceRoleForECRPullThroughCache" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.ecr_pullthroughcache_policy.arn
}
