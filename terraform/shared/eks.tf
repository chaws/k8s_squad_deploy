# 
# This file contains all necessary resources to create an entire EKS cluster.
# I gathered bits and pieces from 3 main tutorials on how to do it:
# 
#   * https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster
#   * https://engineering.finleap.com/posts/2020-02-27-eks-fargate-terraform/
#   * https://www.padok.fr/en/blog/aws-eks-cluster-terraform
# 
# The only resources that need to be previously created are VPC and Subnets:
#   * 1 VPC with an Internet Gateway
#   * 2 Public subnets
#     * EKS requires at least 2 availability zones, thus 2 subnetworks.
#       They're public because we needed the Kubernetes endpoint to be publicly
#       available. If we ever need to place them on a private subnet, we'll
#       need a bastion node.
#   * 2 Private subnets with a NAT way out to the Internet
#     * We'll be using EKS with Fargate integration, and it requires private
#       subnets (it's their requirements)
#   * all that is managed in `vpc.tf`
# 
# Once networking is cleared, the following resources are required for our deploy:
#   * 3 Roles
#     * SQUAD_EKSClusterRole: the main role with access to "eks.amazonaws.com" and "eks-fargate-pods.amazonaws.com"
#       * Policies:
#         * AmazonEKSClusterPolicy (aws managed)
#         * AmazonEKSServicePolicy (aws managed)
#         * AmazonEKSCloudWatchMetricsPolicy (to save logs in CloudWatch)
#     * SQUAD_EKSNodeGroupRole: role to attach to EKS worker nodes, it's like an instance profile for EC2
#       * Policies:
#         * AmazonEKSWorkerNodePolicy (aws managed)
#         * AmazonEKS_CNI_Policy (aws managed)
#         * AmazonSES_SendRawEmail_Policy: allow pods in these nodes to send emails
#         * AmazonEC2ContainerRegistryReadOnly (aws managed)
#     * SQUAD_EKSFargateRole: role to allow Fargate to manage EC2 resources
#       * Policies:
#         * AmazonEKSFargatePodExecutionRolePolicy (aws managed)
#   * 1 CloudWatch log group
#   * 1 EKS Cluster
#     * 1 Fargate Profile that select pods under squad-production and squad-staging namespaces
#     * 1 Worker Node Group that places services required for kubernetes to work


#
#   Roles
#
resource "aws_iam_role" "squad_eks_cluster_role" {
    name = "SQUAD_EKSClusterRole"
    description = "Allow SQUAD_EKSCluster to manage node groups, fargate nodes and cloudwatch logs"
    force_detach_policies = true
    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Service": ["eks.amazonaws.com", "eks-fargate-pods.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
    }]
}
POLICY
}

resource "aws_iam_role" "squad_eks_node_group_role" {
    name = "SQUAD_EKSNodeGroupRole"
    description = "Allow SQUAD_EKSNodeGroup to provision EC2 resources"
    force_detach_policies = true
    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }]
}
POLICY
}

#
#   Policy that allows pods in EKS Node Group to access SES and send email
#
resource "aws_iam_role_policy" "squad_eks_node_group_ses_policy" {
    name = "SQUAD_EKSNodeGroupSESPolicy"
    role = "${aws_iam_role.squad_eks_node_group_role.name}"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
            "Effect": "Allow",
            "Action": [
                "ses:SendRawEmail"
            ],
            "Resource": "*"
    }]
}
EOF
}

resource "aws_iam_role" "squad_eks_fargate_role" {
    name = "SQUAD_EKSFargateRole"
    description = "Allow SQUAD_EKSFargateProfile to allocate resources for running pods"
    force_detach_policies = true
    assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Service": ["eks.amazonaws.com", "eks-fargate-pods.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
    }]
}
POLICY
}


#
#   Attach policies to roles
#
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = "${aws_iam_role.squad_eks_cluster_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    role       = "${aws_iam_role.squad_eks_cluster_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
    policy_arn = "${aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn}"
    role       = "${aws_iam_role.squad_eks_cluster_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
    role       = "${aws_iam_role.squad_eks_fargate_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = "${aws_iam_role.squad_eks_node_group_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = "${aws_iam_role.squad_eks_node_group_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonSES_SendRawEmail_Policy" {
    policy_arn = "${aws_iam_policy.squad_eks_node_group_ses_policy.arn}"
    role       = "${aws_iam_role.squad_eks_node_group_role.name}"
}

# This one is weird, even though we don't use ECR, EKS NodeGroup still requires it
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = "${aws_iam_role.squad_eks_node_group_role.name}"
}


#
#   Configure CloudWatch logs
#
resource "aws_cloudwatch_log_group" "squad_cloudwatch_log_group" {
    name              = "/aws/eks/squad-eks-cluster/cluster"
    retention_in_days = 30
    tags = {
        Name = "SQUAD_CloudWatchLogGroup"
    }
}

resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
    name   = "AmazonEKSClusterCloudWatchMetricsPolicy"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Action": [
            "cloudwatch:PutMetricData"
        ],
        "Resource": "*",
        "Effect": "Allow"
    }]
}
EOF
}


#
#   EKS Cluster
#
resource "aws_eks_cluster" "squad_eks_cluster" {
    name = "SQUAD_EKSCluster"
    tags = {
        Name = "SQUAD_EKSCluster"
    }

    role_arn                  = "${aws_iam_role.squad_eks_cluster_role.arn}"
    enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

    vpc_config {
        subnet_ids = [
            "${aws_subnet.squad_private_subnet_1.id}",
            "${aws_subnet.squad_private_subnet_2.id}",
            "${aws_subnet.qareports_public_subnet_1.id}",
            "${aws_subnet.qareports_public_subnet_2.id}"
        ]
    }

    timeouts {
        delete = "30m"
    }

    depends_on = [
        "aws_iam_role_policy_attachment.AmazonEKSClusterPolicy",
        "aws_iam_role_policy_attachment.AmazonEKSServicePolicy",
        "aws_iam_role_policy_attachment.AmazonEKSCloudWatchMetricsPolicy",
    ]
}


#
#   EKS Node Group
#
resource "aws_eks_node_group" "squad_eks_node_group" {
    cluster_name    = "${aws_eks_cluster.squad_eks_cluster.name}"
    node_group_name = "SQUAD_EKSNodeGroup"
    node_role_arn   = "${aws_iam_role.squad_eks_node_group_role.arn}"
    subnet_ids      = ["${aws_subnet.squad_public_subnet_1.id}", "${aws_subnet.squad_public_subnet_2.id}"]

    # Define autoscale, leave all with 1 for now
    scaling_config {
        desired_size = 1
        max_size     = 1
        min_size     = 1
    }

    depends_on = [
        "aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy",
        "aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy",
        "aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly",
        "aws_iam_role_policy_attachment.AmazonSES_SendRawEmail_Policy",
    ]
}


#
#   Fargate profile: configure production and staging pods to run on Fargate (1 pod per node)
#
resource "aws_eks_fargate_profile" "squad_eks_fargate_profile" {
    cluster_name           = "${aws_eks_cluster.squad_eks_cluster.name}"
    fargate_profile_name   = "SQUAD_EKSFargateProfile"
    pod_execution_role_arn = "${aws_iam_role.squad_eks_fargate_role.arn}"

    # Only private subnets
    subnet_ids = [
        "${aws_subnet.squad_private_subnet_1.id}",
        "${aws_subnet.squad_private_subnet_2.id}"
    ]

    # Make Kubernetes schedule pods in these namespaces to run under Fargate
    selector {
        namespace = "squad-staging"
    }

    selector {
        namespace = "squad-production"
    }

    depends_on = [
        "aws_iam_role_policy_attachment.AmazonEKSFargatePodExecutionRolePolicy"
    ]
}
