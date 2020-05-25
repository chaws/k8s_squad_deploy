service_name = "chaws-qa-reports"

node_type = "t2.micro"

db_node_type = "t2.micro"

region = "us-east-1"

# VPC ID (create)
vpc_id = "vpc-00cda1e895922bde9" # 192.168.0.0/16

# Two public subnets
availability_zone_to_subnet_map = {
  "us-east-1c" = "subnet-008b893007029ac3f" # 192.168.0.0/19
  "us-east-1d" = "subnet-08d0c0ebb23abe700" # 192.168.32.0/19
}

ssh_key_name = "chaws_ssh_key"

# us-east-1, 16.04LTS, hvm:ebs-ssd
# see https://cloud-images.ubuntu.com/locator/ec2/
ami_id = "ami-0b383171"
