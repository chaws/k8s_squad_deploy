variable "ssh_key_name" { type = "string" }
variable "vpc_id" { type = "string" }
variable "region" {
    type = "string"
    default = "us-east-1"
}
variable "db_node_type" { type = "string" }
