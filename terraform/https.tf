## ACM cert
#resource "aws_acm_certificate" "acm-cert" {
#    domain_name = "next-staging.net"
#    validation_method = "NONE"
#}
#
#resource "aws_route53_record" "qareports-domain" {
#  zone_id = "${var.route53_zone_id}"
#  name = "${local.local_dns_name}"
#  type = "A"
#  alias {
#    name = "${aws_lb.qa-reports-lb.dns_name}"
#    zone_id = "${aws_lb.qa-reports-lb.zone_id}"
#    evaluate_target_health = false
#  }
#}
