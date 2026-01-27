resource "aws_acm_certificate" "ecs-domain-certificate" {
  domain_name               = local.certificate_domain_names[0]
  subject_alternative_names = length(local.certificate_domain_names) > 1 ? slice(local.certificate_domain_names, 1, length(local.certificate_domain_names)) : []
  validation_method         = "DNS"
  tags = {
    Contact = "Abdelhak"
    Project = var.project
  }
}


data "aws_route53_zone" "ecs_domain" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "ecs_cert_vald_rec" {
for_each = {
  for validation_option in aws_acm_certificate.ecs-domain-certificate.domain_validation_options : validation_option.domain_name => {
    name   = validation_option.resource_record_name
    record = validation_option.resource_record_value
    type   = validation_option.resource_record_type
  }
}

  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.ecs_domain.zone_id
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}


resource "aws_acm_certificate_validation" "ecs_domain_cert_vals" {
  certificate_arn         = aws_acm_certificate.ecs-domain-certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.ecs_cert_vald_rec : record.fqdn]
}
