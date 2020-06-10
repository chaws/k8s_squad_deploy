#
#   Security group for RabbitMQ instance
#     * it should allow external ssh connections
#     * it should allow squad services to connect to queues
#     * it should allow external outgoing access
#
resource "aws_security_group" "squad_rabbitmq_security_group" {
    name = "SQUAD_RabbitMQSecurityGroup"
    description = "Security Group for RabbitMQ instance"
    vpc_id = "${aws_vpc.squad_vpc.id}"

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
        cidr_blocks = ["${aws_subnet.squad_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }
    ingress {
        from_port   = 5671
        to_port     = 5672
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.squad_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }
    ingress {
        from_port   = 25672
        to_port     = 25672
        protocol    = "tcp"
        cidr_blocks = ["${aws_subnet.squad_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }

    # Outbound internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#
#   RabbitMQ instance to be shared among production and staging
#
resource "aws_instance" "squad_rabbitmq_instance" {
    tags = {
        Name = "SQUAD_RabbitMQ"
    }

    # Instance type and size
    ami = "${var.ami_id}"
    instance_type = "t3a.small"

    # Networking and security
    subnet_id = "${aws_subnet.squad_public_subnet_1.id}"
    availability_zone = "${aws_subnet.squad_public_subnet_1.availability_zone}"
    vpc_security_group_ids = ["${aws_security_group.squad_rabbitmq_security_group.id}"]

    # Install RabbitMQ
    user_data = "${file("../scripts/rabbitmq_install.sh")}"

    # Define ssh key and user
    key_name = "${aws_key_pair.squad_ssh_key.key_name}"
    connection {
        user = "ubuntu"
    }
}
