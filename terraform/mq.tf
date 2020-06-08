# Instance security group to access the instances over SSH and HTTP
resource "aws_security_group" "qareports_mq_sg" {
    name = "chaws ec2 www"
    description = "Default SG for qa-reports webservers"
    vpc_id = "${aws_vpc.qareports_vpc.id}"

    # SSH access from anywhere
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # RabbitMQ clustering traffic inside local network
    # source: https://www.rabbitmq.com/networking.html
    ingress {
        from_port   = 4369
        to_port     = 4369
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.qareports_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }
    ingress {
        from_port   = 5671
        to_port     = 5672
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.qareports_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }
    ingress {
        from_port   = 25672
        to_port     = 25672
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.qareports_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }

    # outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "qareports_mq_instance" {
    connection {
        user = "ubuntu"
    }

    tags = {
        Name = "qareports mq instance"
    }

    instance_type = "t3a.small"
    ami = "${var.ami_id}"
    key_name = "${var.ssh_key_name}"
    vpc_security_group_ids = ["${aws_security_group.qareports_mq_sg.id}"]

    # Create in a public subnet so it can get an ip
    subnet_id = "${aws_subnet.qareports_public_subnet_1.id}"
    availability_zone = "${aws_subnet.qareports_public_subnet_1.availability_zone}"

    user_data = "${file("scripts/rabbitmq_install.sh")}"
}
