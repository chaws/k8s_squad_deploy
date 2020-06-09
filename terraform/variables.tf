variable "service_name" { type = "string" }
variable "availability_zone_to_subnet_map" { type = "map" }
variable "ssh_key_name" { type = "string" }
variable "ami_id" { type = "string" }
variable "vpc_id" { type = "string" }
variable "region" { type = "string" }
variable "node_type" { type = "string" }
variable "db_node_type" { type = "string" }

provider "aws" {
  region = "${var.region}"
}
