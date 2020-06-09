# A security group for the database
resource "aws_security_group" "qareports_db_sg" {
    name        = "qareports-postgresql"
    description = "Security group for qareports database"
    vpc_id      = "${aws_vpc.qareports_vpc.id}"

    # Postgres uses port 5432
    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.qareports_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }

    # Allow ssh access
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_db_subnet_group" "qareports_db_subnet_group" {
    name       = "chawsqareports db subnet group"
    subnet_ids = ["${aws_subnet.qareports_private_subnet_1.id}", "${aws_subnet.qareports_private_subnet_2.id}"]

  tags {
    Name = "chawsqareports DB subnet group"
  }
}

resource "aws_db_parameter_group" "qareports_db_parameter_group" {
  name        = "chawsqa-reports-postgresql-params"
  family      = "postgres11"
  description = "RDS default cluster parameter group"

  parameter {
    name  = "log_min_duration_statement"
    value = 500
  }
}

resource "aws_db_instance" "qareports_db_instance" {
    allocated_storage = "20"
    storage_type = "gp2" # SSD
    apply_immediately = true
    engine = "postgres"
    instance_class = "db.${var.db_node_type}"
    name = "qareports"
    username = "qareports"
    password = "easy_password"
    availability_zone = "us-east-1c"
    db_subnet_group_name = "${aws_db_subnet_group.qareports_db_subnet_group.name}"
    parameter_group_name = "${aws_db_parameter_group.qareports_db_parameter_group.name}"
    multi_az = false
    backup_retention_period = 7 # days
    backup_window = "23:20-23:50"
    maintenance_window = "Sun:20:00-Sun:23:00"
    vpc_security_group_ids = ["${aws_security_group.qareports_db_sg.id}"]
}
