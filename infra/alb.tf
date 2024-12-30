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
  port        = 8443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.keycloak.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "302"
    protocol            = "HTTPS"
  }

  tags = {
    Name        = "${var.project}.${terraform.workspace}-ecs-tg"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"  # Update as needed
  certificate_arn   = aws_acm_certificate_validation.cert_validation.certificate_arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol = "HTTPS"
      port     = "443"
      status_code = "HTTP_301"
    }
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

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.subdomain_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate" "cert" {
  domain_name               = "${var.project}.${terraform.workspace}.dorokhovich.de"
  validation_method         = "DNS"
  subject_alternative_names = ["www.${var.project}.${terraform.workspace}.dorokhovich.de"]

  tags = {
    Environment = terraform.workspace
    Project     = var.project
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}