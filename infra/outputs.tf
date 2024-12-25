output "alb_dns" {
  value = aws_lb.public_alb.dns_name
}

output "workspace" {
  value = terraform.workspace
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
