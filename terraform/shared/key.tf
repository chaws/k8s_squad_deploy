#
#   SQUAD SSH key pair is used to log into the following EC2 instances:
#     * RabbitMQ
#     * NAT instance
#     * EKS node group
#
resource "aws_key_pair" "squad_ssh_key" {
    key_name   = "squad_ssh_key"
    public_key = "${file("${path.module}/../scripts/squad_public_key")}"
}
