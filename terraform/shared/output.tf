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

# Find a way to encrypt this file
resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "${path.module}/../../kubeconfig.shared"
}

#
#   Write shared.tfvars
#
data "template_file" "shared_vars" {
  template = "${file("${path.module}/templates/shared.tfvars.tpl")}"

  vars = {
    ssh_key_name = "${aws_key_pair.squad_ssh_key.key_name}" {
    vpc_id       = "${aws_vpc.squad_vpc.id}"
    subnet1_id   = "${aws_subnet.squad_private_subnet_1.id}"
    subnet1_cidr = "${aws_subnet.squad_private_subnet_1.cidr_block}"
    subnet2_id   = "${aws_subnet.squad_private_subnet_2.id}"
    subnet2_cidr = "${aws_subnet.squad_private_subnet_2.cidr_block}"
  }
}

# Find a way to encrypt this file
resource "local_file" "shared_vars" {
  content  = "${data.template_file.shared_vars.rendered}"
  filename = "${path.module}/../shared.tfvars"
}
