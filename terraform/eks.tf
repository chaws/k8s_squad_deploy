resource "aws_iam_role" "eks_cluster_role" {
  name = "qareports-eks-cluster-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["eks.amazonaws.com", "eks-fargate-pods.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks_cluster_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks_cluster_role.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
  policy_arn = "${aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn}"
  role       = "${aws_iam_role.eks_cluster_role.name}"
}

# Configure cloudwatch log groups
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/qareports-eks-cluster/cluster"
  retention_in_days = 30

  tags = {
    Name = "qareports-eks-cloudwatch-log-group"
  }
}

resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
  name   = "AmazonEKSClusterCloudWatchMetricsPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_eks_cluster" "aws_eks" {
  name     = "qareports-eks-cluster"
  role_arn = "${aws_iam_role.eks_cluster_role.arn}"
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  vpc_config {
    subnet_ids = ["${aws_subnet.qareports_private_subnet_1.id}", "${aws_subnet.qareports_private_subnet_2.id}", "${aws_subnet.qareports_public_subnet_1.id}", "${aws_subnet.qareports_public_subnet_2.id}"]
  }

  tags = {
    Name = "qareports-eks-cluster"
  }

  timeouts {
    delete = "30m"
  }

  depends_on = [
    "aws_iam_role_policy_attachment.AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.AmazonEKSServicePolicy",
  ]
}

resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group-tuto"
  force_detach_policies = true
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks_nodes.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks_nodes.name}"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks_nodes.name}"
}

resource "aws_eks_node_group" "node" {
  cluster_name    = "${aws_eks_cluster.aws_eks.name}"
  node_group_name = "node_tuto"
  node_role_arn   = "${aws_iam_role.eks_nodes.arn}"
  subnet_ids      = ["${aws_subnet.qareports_public_subnet_1.id}", "${aws_subnet.qareports_public_subnet_2.id}"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    "aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy",
    "aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy",
  ]
}

resource "aws_eks_fargate_profile" "fp-staging" {
  cluster_name           = "${aws_eks_cluster.aws_eks.name}"
  fargate_profile_name   = "fp-qareports-staging"
  pod_execution_role_arn = "${aws_iam_role.fargate_pod_execution_role.arn}"
  subnet_ids      = ["${aws_subnet.qareports_private_subnet_1.id}", "${aws_subnet.qareports_private_subnet_2.id}"]

  selector {
    namespace = "qareports-staging"
  }
}

resource "aws_eks_fargate_profile" "fp-production" {
  cluster_name           = "${aws_eks_cluster.aws_eks.name}"
  fargate_profile_name   = "fp-qareports-production"
  pod_execution_role_arn = "${aws_iam_role.fargate_pod_execution_role.arn}"
  subnet_ids      = ["${aws_subnet.qareports_private_subnet_1.id}", "${aws_subnet.qareports_private_subnet_2.id}"]

  selector {
    namespace = "qareports-production"
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = "${aws_iam_role.fargate_pod_execution_role.name}"
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
