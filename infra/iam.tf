resource "aws_iam_role" "ecsTaskExecutionRole" {
  name                = "${var.project}-${terraform.workspace}-execution-task-role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    Name        = "${var.project}-${terraform.workspace}-iam-ecsTaskExecutionRole-role"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_iam_policy" "ecr_pullthroughcache_policy" {
  name        = "${var.project}-${terraform.workspace}-ecr-pullthrough-policy"
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
        Resource = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:${var.project}-${terraform.workspace}-quay/keycloak"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${terraform.workspace}-ecr-pullthrough-policy"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "${var.project}-${terraform.workspace}-secrets-manager-policy"
  description = "Policy to allow ECS task execution role to access Secrets Manager secrets"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource": [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.keycloak_admin.arn
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${terraform.workspace}-secrets-manager-policy"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_iam_role" "appAutoscalingRole" {
  name = "${var.project}-${terraform.workspace}-appAutoscalingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "app_autoscaling_policy" {
  name = "${var.project}-${terraform.workspace}-app-autoscaling-policy"
  role = aws_iam_role.appAutoscalingRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
      },
    ]
  })
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

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionPolicy_AWSServiceRoleForSecretManager" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}
