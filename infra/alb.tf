resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-${terraform.workspace}-alb-sg"
  description = "Allow inbound traffic to ALB"
  vpc_id      = aws_vpc.keycloak.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows public access to port 80
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows public access to port 443
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${terraform.workspace}-alb-sg"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_lb" "public_alb" {
  name               = "${var.project}-${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public.*.id

  tags = {
    Name        = "${var.project}-${terraform.workspace}-alb"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_lb_target_group" "ecs_target_group" {
  name        = "${var.project}-${terraform.workspace}-ecs-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.keycloak.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "302"
  }

  tags = {
    Name        = "${var.project}.${terraform.workspace}-ecs-tg"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}

resource "aws_route53_record" "alb_record" {
  zone_id = aws_route53_zone.subdomain_zone.zone_id
  name    = "${var.project}.${terraform.workspace}.dorokhovich.de"
  type    = "A"

  alias {
    name                   = aws_lb.public_alb.dns_name
    zone_id                = aws_lb.public_alb.zone_id
    evaluate_target_health = true
  }
}
