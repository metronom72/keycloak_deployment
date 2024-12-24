output "alb_dns" {
  value = aws_lb.public_alb.dns_name
}

output "workspace" {
  value = terraform.workspace
}
