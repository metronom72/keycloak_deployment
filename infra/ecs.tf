resource "aws_ecr_pull_through_cache_rule" "quay" {
  ecr_repository_prefix = "${var.project}-${terraform.workspace}-quay"
  upstream_registry_url = "quay.io"
}

resource "aws_security_group" "ecs_cluster_sg" {
  name        = "${var.project}-${terraform.workspace}-ecs_cluster_sg"
  description = "Security group for ECS cluster in private subnets"
  vpc_id      = aws_vpc.keycloak.id

  ingress {
    description = "Allow communication within ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${terraform.workspace}-ecs_cluster_sg"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_ecs_cluster" "keycloak_ecs_cluster" {
  name = "${var.project}-${terraform.workspace}-cluster"

  tags = {
    Name        = "${var.project}-${terraform.workspace}-ecs-cluster"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_cloudwatch_log_group" "keycloak_log_group" {
  name = "${var.project}-${terraform.workspace}"

  tags = {
    Name        = "${var.project}-${terraform.workspace}-log-group"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_ecs_task_definition" "keycloak_ecs_task" {
  family = "${var.project}-task"

  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  memory = "2048"
  cpu = "1024"
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn      = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project}-${terraform.workspace}-container",
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.project}/${terraform.workspace}:latest"
      memory    = 2048
      cpu       = 1024
      essential = true
      portMappings = [
        {
          containerPort = 8443
          protocol      = "tcp"
        },
        {
          containerPort = 8080
          protocol      = "tcp"
        },
        {
          containerPort = 9000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "KC_DB"
          value = "postgres"
        },
        {
          name  = "KC_DB_URL"
          value = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}/${var.db_name}"
        },
        {
          name  = "DB_DATABASE"
          value = var.db_name
        },
        {
          name  = "KC_FEATURES"
          value = "preview"
        },
        {
          name  = "KC_HEALTH_ENABLED"
          value = "true"
        },
        {
          name  = "KC_METRICS_ENABLED"
          value = "true"
        },
        {
          name  = "KC_CACHE_CONFIG_FILE"
          value = "cache-ispn-jdbc-ping.xml"
        },
        {
          name  = "KC_HOSTNAME"
          value = "${var.project}.${terraform.workspace}.dorokhovich.de"
        },
        {
          name  = "KC_HOSTNAME_STRICT"
          value = "true"
        },
        {
          name  = "KC_HOSTNAME_STRICT_HTTPS"
          value = "true"
        }
      ]
      secrets = [
        {
          name      = "KEYCLOAK_ADMIN"
          valueFrom = "${aws_secretsmanager_secret.keycloak_admin.arn}:username::"
        },
        {
          name      = "KEYCLOAK_ADMIN_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.keycloak_admin.arn}:password::"
        },
        {
          name      = "KC_DB_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:username::"
        },
        {
          name      = "KC_DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.keycloak_log_group.name
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "keycloak"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl --head -fsS https://localhost:9000/health >> /var/log/keycloak-health.log 2>&1 || exit 0"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project}-${terraform.workspace}-ecs-task"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_ecs_service" "keycloak_ecs_service" {
  name                  = "${var.project}-${terraform.workspace}-ecs-service"
  cluster               = aws_ecs_cluster.keycloak_ecs_cluster.id
  task_definition       = "${aws_ecs_task_definition.keycloak_ecs_task.family}:${max(aws_ecs_task_definition.keycloak_ecs_task.revision, data.aws_ecs_task_definition.keycloak.revision)}"
  launch_type           = "FARGATE"
  scheduling_strategy   = "REPLICA"
  desired_count         = 2
  force_new_deployment  = true

  availability_zone_rebalancing = "ENABLED"
  propagate_tags                = "TASK_DEFINITION"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs_cluster_sg.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "${var.project}-${terraform.workspace}-container"
    container_port   = 8443
  }

  tags = {
    Name        = "${var.project}-${terraform.workspace}-ecs-task"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.project}-${terraform.workspace}-vpc-endpoint-sg"
  vpc_id      = aws_vpc.keycloak.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_cluster_sg.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_cluster_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${terraform.workspace}-vpc-endpoint-sg"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_appautoscaling_target" "ecs_autoscaling_target" {
  min_capacity       = 2
  max_capacity       = 12
  resource_id        = "service/${aws_ecs_cluster.keycloak_ecs_cluster.name}/${aws_ecs_service.keycloak_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  role_arn = aws_iam_role.appAutoscalingRole.arn
}

resource "aws_appautoscaling_policy" "cpu_scaling_policy" {
  name               = "cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_autoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60.0  # Target CPU utilization percentage
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory_scaling_policy" {
  name               = "memory-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_autoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 70.0  # Target Memory utilization percentage
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "request_scaling_policy" {
  name               = "request-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_autoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name        = "RequestCountPerTarget"
      namespace          = "AWS/ApplicationELB"
      statistic           = "Sum"
      dimensions {
        name  = "LoadBalancer"
        value = aws_lb.public_alb.name
      }

      dimensions {
        name  = "TargetGroup"
        value = aws_lb_target_group.ecs_target_group.name
      }
      unit = "Count"
    }

    target_value = 300
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}