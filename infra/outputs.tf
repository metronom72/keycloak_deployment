output "alb_dns" {
  value = aws_lb.public_alb.dns_name
}

output "workspace" {
  value = terraform.workspace
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "hosted_zone" {
  value = aws_route53_zone.subdomain_zone.name
}

output "name_servers" {
  value = aws_route53_zone.subdomain_zone.name_servers
}
