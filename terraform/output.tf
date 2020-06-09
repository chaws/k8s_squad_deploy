data "template_file" "kubeconfig" {

  template = "${file("${path.module}/templates/kubeconfig.tpl")}"

  vars = {
    kubeconfig_name           = "${aws_eks_cluster.aws_eks.name}"
    clustername               = "${aws_eks_cluster.aws_eks.name}"
    endpoint                  = "${aws_eks_cluster.aws_eks.endpoint}"
    cluster_auth_base64       = "${aws_eks_cluster.aws_eks.certificate_authority.0.data}"
  }
}

resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "kubeconfig.shared"
}
