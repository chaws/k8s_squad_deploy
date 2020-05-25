# Create cluster

After spending a couple of weeks trying to come up with a working example of
terraform scripts to manage an EKS cluster, I decided to go for `eksctl` tool.
It's much easier and it's the official way of interacting with AWS EKS: https://eksctl.io/

I created this experiment to try to fit a case where some resources are previously created
but some will need to be fully created by eksctl tool.

We first need to create some AWS resources and then run eksctl tool to create the rest.
Finally, we run a few kubectl commands to get squad up and running in a production fashion.

## AWS resources

Some AWS resources are necessary to be previously created in order to get RabbitMQ, PostgreSQL
and some networking property needed for SQUAD to work. Create them by:

```bash
$ ./terraform apply
```

This will create:
* 1 ec2 instance to run RabbitMQ
* 1 rds instance with PostgreSQL
* 1 VPC with 4 subnets
* security groups?

## EKS Cluster

Create cluster with

```bash
$ ./bin/eksctl create cluster -f k8s/cluster.yml
```

This should be configured with previously created VPC resources managed by terraform.
Also, it's worh noting resources being created:
* 1 eks cluster 
* 1 node to accomodate some kubernetes services
* 3 fargate profiles:
  * 1 for production namespace pods
  * 1 for staging namespace pods
  * 1 for default, kube-system and kubernetes-dashboard namespace
* Some roles and security groups and NET/Internet gateways
