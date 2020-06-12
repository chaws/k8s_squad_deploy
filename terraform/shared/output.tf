#
#   Write kubeconfig
#
data "template_file" "kubeconfig" {
    template = "${file("${path.module}/templates/kubeconfig.tpl")}"

    vars = {
        kubeconfig_name     = "${aws_eks_cluster.squad_eks_cluster.name}"
        clustername         = "${aws_eks_cluster.squad_eks_cluster.name}"
        endpoint            = "${aws_eks_cluster.squad_eks_cluster.endpoint}"
        cluster_auth_base64 = "${aws_eks_cluster.squad_eks_cluster.certificate_authority.0.data}"
    }
}
resource "local_file" "kubeconfig" {
    content  = "${data.template_file.kubeconfig.rendered}"
    filename = "${path.module}/../generated/kubeconfig"
}

#
#   Write shared.tfvars
#
data "template_file" "shared_vars" {
  template = "${file("${path.module}/templates/shared.tfvars.tpl")}"

  vars = {
    vpc_id       = "${aws_vpc.squad_vpc.id}"
    region       = "${var.region}"
    ssh_key_name = "${aws_key_pair.squad_ssh_key.key_name}"
    subnet1_id   = "${aws_subnet.squad_public_subnet_1.id}"
    subnet1_cidr = "${aws_subnet.squad_public_subnet_1.cidr_block}"
    subnet2_id   = "${aws_subnet.squad_public_subnet_2.id}"
    subnet2_cidr = "${aws_subnet.squad_public_subnet_2.cidr_block}"
  }
}
resource "local_file" "shared_vars" {
    content  = "${data.template_file.shared_vars.rendered}"
    filename = "${path.module}/../generated/shared.tfvars"
}

#
#   Save RabbitMQ host (private ip)
#
data "template_file" "rabbitmq_host" {
    template = "$${rabbitmq_host}"
    vars = {
        rabbitmq_host = "${aws_instance.squad_rabbitmq_instance.private_ip}"
    }
}
resource "local_file" "rabbitmq_host" {
    content  = "${data.template_file.rabbitmq_host.rendered}"
    filename = "${path.module}/../generated/rabbitmq_host"
}
