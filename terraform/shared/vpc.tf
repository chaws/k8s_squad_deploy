# This VPC configuration set up 1 Virtual Private Cloud
# with 4 sub networks, 2 public and 2 private ones, which
# seems to be the standard way to go
# 
#          +---------------------------------------------------------------------+
#          |                                VPC                                  |
#          |                          "192.168.0.0/16"                           |
#          |                             65534 hosts                             |
#          |   +-------------------------------------------------------------+   |
#          |   |   Public Subnets with routing table to Internet Gateway     |   |
#          |   |   +--------------------------+--------------------------+   |   |
#          |   |   |         Subnet1          |         Subnet2          |   |   |
#          |   |   |     "192.168.32.0/19"    |     "192.168.0.0/19"     |   |   |
#          |   |   |        8190 hosts        |        8190 hosts        |   |   |
#          |   |   +--------------------------+--------------------------+   |   |
#          |   +-------------------------------------------------------------+   |
#          |                                                                     |
#          |   +-------------------------------------------------------------+   |
#          |   |   Private Subnets with routing table to NAT Instance        |   |
#          |   |       (resources need to get out on the Internet)           |   |
#          |   |   +--------------------------+--------------------------+   |   |
#          |   |   |       Subnet1            |          Subnet2         |   |   |
#          |   |   |     "192.168.96.0/19"    |     "192.168.64.0/19"    |   |   |
#          |   |   |        8190 hosts        |        8190 hosts        |   |   |
#          |   |   +--------------------------+--------------------------+   |   |
#          |   +------------------------------------------------------------ +   |
#          +-------------------------------------------------------------------- +
# 
# It's OK to have RabbitMQ and Postgres on Public Subnets, having their
# subgroups restricted to only sources from within the same subnet
# 
# When creating EKS clusters, at least two subnets are required.
# 
# "When you create an Amazon EKS cluster, you specify the VPC subnets
#  for your cluster to use. Amazon EKS requires subnets in at least two
#  Availability Zones. We recommend a VPC with public and private subnets
#  so that Kubernetes can create public load balancers in the public
#  subnets that load balance traffic to pods running on worker nodes that
#  are in private subnets."
# ref: https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html

resource "aws_vpc" "squad_vpc" {
    cidr_block = "192.168.0.0/16"

    tags = {
        Name = "SQUAD_VPC"
    }
}

resource "aws_internet_gateway" "squad_igw" {
    vpc_id = "${aws_vpc.squad_vpc.id}"

    tags = {
        Name = "SQUAD_InternetGateway"
    }
}

#
#   Private Subnets
#
resource "aws_subnet" "squad_private_subnet_1" {
    vpc_id     = "${aws_vpc.squad_vpc.id}"
    cidr_block = "192.168.96.0/19"
    availability_zone = "us-east-1d"
    tags = {
        "kubernetes.io/cluster/SQUAD_EKSCluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1
        "Name" = "SQUAD_PrivateSubnet1"
    }
}

resource "aws_route_table" "squad_private_subnet_1_rt" {
    vpc_id = "${aws_vpc.squad_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.squad_nat_instance.id}"
    }
}

resource "aws_route_table_association" "squad_private_subnet_1_rt_association" {
    subnet_id = "${aws_subnet.squad_private_subnet_1.id}"
    route_table_id = "${aws_route_table.squad_private_subnet_1_rt.id}"
}

resource "aws_subnet" "squad_private_subnet_2" {
    vpc_id     = "${aws_vpc.squad_vpc.id}"
    cidr_block = "192.168.64.0/19"
    availability_zone = "us-east-1c"
    tags = {
        "kubernetes.io/cluster/SQUAD_EKSCluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1
        "Name" = "SQUAD_PrivateSubnet2"
    }
}

resource "aws_route_table" "squad_private_subnet_2_rt" {
    vpc_id = "${aws_vpc.squad_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.squad_nat_instance.id}"
    }
}

resource "aws_route_table_association" "squad_private_subnet_2_rt_association" {
    subnet_id = "${aws_subnet.squad_private_subnet_2.id}"
    route_table_id = "${aws_route_table.squad_private_subnet_2_rt.id}"
}

#
#   NAT Instance: instead of using an expensive NAT Gateway (0.04/hr + 0.04/GB)
#   configure a regular ec2 instance located in the public network to act as
#   NAT gateway
#
resource "aws_security_group" "squad_nat_instance_security_group" {
    name = "SQUAD_NATSecurityGroup"
    description = "Allow traffic to pass from the private subnet to the internet"
    vpc_id = "${aws_vpc.squad_vpc.id}"


    # Allow private subnet to access port 80 and 443
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${aws_subnet.squad_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${aws_subnet.squad_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }

    # Generic firewall rules
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.squad_vpc.cidr_block}"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow exiting to LAVA servers
    ingress {
        from_port = 5500
        to_port = 5599
        protocol = "tcp"
        cidr_blocks = ["${aws_subnet.squad_private_subnet_1.cidr_block}", "${aws_subnet.qareports_private_subnet_2.cidr_block}"]
    }
    egress {
        from_port = 5500
        to_port = 5599
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "squad_nat_instance" {
    tags = {
        Name = "SQUAD_NAT"
    }
    ami = "ami-0b383171" # us-east-1, 16.04LTS, hvm:ebs-ssd
    instance_type = "t3a.micro"
    key_name = "${aws_key_pair.squad_ssh_key.key_name}"
    vpc_security_group_ids = ["${aws_security_group.squad_nat_instance_security_group.id}"]
    associate_public_ip_address = true

    # Place instance in a public subnet
    subnet_id = "${aws_subnet.squad_public_subnet_1.id}"
    availability_zone = "${aws_subnet.squad_public_subnet_1.availability_zone}"

    # Disable check if network packages belong to the instance
    # needed for NAT instances
    source_dest_check = false 

    # Turn on ip forwarding and enable NAT translation
    user_data = "${file("../scripts/nat_config.sh")}"
}

resource "aws_eip" "squad_nat_eip" {
    instance = "${aws_instance.squad_nat_instance.id}"
    vpc = true
    depends_on = ["aws_internet_gateway.squad_igw"]
}

#
#   Public Subnets
#
resource "aws_subnet" "squad_public_subnet_1" {
    vpc_id     = "${aws_vpc.squad_vpc.id}"
    cidr_block = "192.168.32.0/19"
    availability_zone = "us-east-1d"
    map_public_ip_on_launch = true
    tags = {
        "kubernetes.io/cluster/SQUAD_EKSCluster" = "shared"
        "kubernetes.io/role/elb" = 1
        "Name" = "SQUAD_PublicSubnet1"
    }
}

resource "aws_route_table" "squad_public_subnet_1_rt" {
    vpc_id = "${aws_vpc.squad_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.squad_igw.id}"
    }
}

resource "aws_route_table_association" "squad_public_subnet_1_rt_association" {
    subnet_id = "${aws_subnet.squad_public_subnet_1.id}"
    route_table_id = "${aws_route_table.squad_public_subnet_1_rt.id}"
}

resource "aws_subnet" "squad_public_subnet_2" {
    vpc_id     = "${aws_vpc.squad_vpc.id}"
    cidr_block = "192.168.0.0/19"
    availability_zone = "us-east-1c"
    map_public_ip_on_launch = true
    tags = {
        "kubernetes.io/cluster/SQUAD_EKSCluster" = "shared"
        "kubernetes.io/role/elb" = 1
        "Name" = "SQUAD_PublicSubnet2"
    }
}

resource "aws_route_table" "squad_public_subnet_2_rt" {
    vpc_id = "${aws_vpc.squad_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.squad_igw.id}"
    }
}

resource "aws_route_table_association" "squad_public_subnet_2_rt_association" {
    subnet_id = "${aws_subnet.squad_public_subnet_2.id}"
    route_table_id = "${aws_route_table.squad_public_subnet_2_rt.id}"
}
