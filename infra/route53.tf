resource "aws_route53_zone" "subdomain_zone" {
  name = "${var.project}.${terraform.workspace}.dorokhovich.de"

  tags = {
    Name        = "${var.project}.${terraform.workspace}.dorokhovich.de"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_route53_record" "subdomain_delegation" {
  zone_id = data.aws_route53_zone.parent_zone.zone_id
  name    = "${var.project}.${terraform.workspace}.dorokhovich.de"
  type    = "NS"

  records = aws_route53_zone.subdomain_zone.name_servers
  ttl     = 300
}
