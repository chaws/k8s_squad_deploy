# Store state file in S3
# This has to be hard coded because it is loaded before anything else.
# terraform {
#     backend "s3" {
#         bucket = "squad-terraform-state"
#         key = "squad/${environment}/terraform.tfstate"
#         region = "us-east-1"
#     }
# }

variable "environment" { type = "string" }
variable "db_node_type" { type = "string" }
variable "db_max_allocated_storage" { type = "string" }
variable "ssh_key_name" { type = "string" }
variable "vpc_id" { type = "string" }
variable "region" {
    type = "string"
    default = "us-east-1"
}

provider "aws" {
  region = "${var.region}"
}


#
#   RDS
#
module "rds" {
  source = "modules/rds"
  environment = "${var.environment}"
  db_host_size = "${var.db_node_type}"
  vpc_id = "${var.vpc_id}"
  instance_security_groups = ["${module.webservers.qa-reports-ec2-worker-sg-id}",
                               "${module.webservers.qa-reports-ec2-www-sg-id}"
                             ]

  db_password = "${lookup(local.rds_env_db_password, var.environment, false)}"
  db_storage = "${lookup(local.rds_env_db_storage, var.environment, false)}"
  db_max_storage = "${var.db_max_allocated_storage}"
}
