#
#   Save database host
#
data "template_file" "database_host" {
    template = "$${database_host}"
    vars = {
        database_host  = "${aws_db_instance.squad_rds_instance.address}"
    }
}

resource "local_file" "database_host" {
    content  = "${data.template_file.database_host.rendered}"
    filename = "${path.module}/generated/${var.environment}_database_host"
}
