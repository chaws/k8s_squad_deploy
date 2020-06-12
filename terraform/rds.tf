variable "vpc_id"         { type = "string" }
variable "region"         { type = "string" }
variable "subnet1_id"     { type = "string" }
variable "subnet1_cidr"   { type = "string" }
variable "subnet2_id"     { type = "string" }
variable "subnet2_cidr"   { type = "string" }
variable "environment"    { type = "string" }
variable "db_storage"     { type = "string" }
variable "db_max_storage" { type = "string" }
variable "db_node_type"   { type = "string" }
variable "db_name"        { type = "string" }
variable "db_username"    { type = "string" }
variable "db_password"    { type = "string" }

# A security group for the database
resource "aws_security_group" "squad_rds_security_group" {
    name        = "SQUAD_RDSSecurityGroup_${var.environment}"
    description = "Security group for squad database"
    vpc_id      = "${var.vpc_id}"

    # Postgres uses port 5432
    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["${var.subnet1_cidr}", "${var.subnet2_cidr}"]
    }

    # Outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_db_subnet_group" "squad_rds_subnet_group" {
    name       = "${var.environment}squad-rds-subnet-group"
    subnet_ids = ["${var.subnet1_id}", "${var.subnet2_id}"]

    tags {
        Name = "SQUAD_RDSSubnetGroup_${var.environment}"
    }
}

resource "aws_db_parameter_group" "squad_rds_parameter_group" {
    name        = "${var.environment}squad-rds-parameter-group"
    family      = "postgres11"
    description = "RDS parameter group"

    parameter {
        name  = "log_min_duration_statement"
        value = 500
    }
}

resource "aws_db_instance" "squad_rds_instance" {
    allocated_storage = "${var.db_storage}"
    max_allocated_storage = "${var.db_max_storage}"
    storage_type = "gp2" # SSD
    apply_immediately = true
    engine = "postgres"
    instance_class = "db.${var.db_node_type}"
    name = "${var.db_name}"
    username = "${var.db_username}"
    password = "${var.db_password}"
    availability_zone = "${var.region}a"
    db_subnet_group_name = "${aws_db_subnet_group.squad_rds_subnet_group.name}"
    parameter_group_name = "${aws_db_parameter_group.squad_rds_parameter_group.name}"
    multi_az = false
    backup_retention_period = 7 # days
    backup_window = "23:20-23:50"
    maintenance_window = "Sun:20:00-Sun:23:00"
    vpc_security_group_ids = ["${aws_security_group.squad_rds_security_group.id}"]
}
