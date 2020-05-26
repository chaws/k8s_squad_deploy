# # ACM cert
# resource "aws_acm_certificate" "acm-cert" {
#     domain_name = "${var.canonical_dns_name}"
#     subject_alternative_names = ["${local.local_dns_name}"]
#     validation_method = "NONE"
# }
