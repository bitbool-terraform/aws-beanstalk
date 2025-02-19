data "aws_route53_zone" "base" {
  count = var.createRoute53Records ? 1 : 0

  name         = try(var.route53BaseDomain,null)
  private_zone = false
}


resource "aws_route53_record" "bean" {
  for_each =  var.createRoute53Records ? var.route53Records : {}

  zone_id = data.aws_route53_zone.base[0].zone_id
  name    = each.value.url
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.app.cname
    zone_id                = data.aws_elastic_beanstalk_hosted_zone.app.id
    evaluate_target_health = true
  }
}
