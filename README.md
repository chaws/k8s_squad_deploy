# qa-reports.linaro.org deployment scripts

You've reached qa-reports deployment scripts. This repository contains all
that's necessary to hopefuly get an instance of SQUAD set up for production
use.

Recently we moved from ansible managed EC2 instances in AWS to containerized
deployment with Kubernetes and EKS, again in AWS.

This repo creates 3 different environments of SQUAD: dev, staging and production.
Both production and staging are hosted in Fargate nodes shared in a single Kubernetes
cluster in EKS. The dev environment is accomplished by spinning up 3 local virtual machines,
being 2 for Kubernetes master/worker nodes and 1 for PostgreSQL/RabbitMQ services.

# Commands

Here is a list of common commands you might want to run to manage qareports:

* `./qareports dev up` creates k8s cluster, RabbitMQ and PostgreSQL instance and deploy squad
* `./qareports dev upgrade` upgrades SQUAD and its settings
* `./qareports dev destroy` destroys development deploy

## Cheatsheet of commands to use on a daily basis

Over the time we noticed that some utility commands might have been added to this deploy to ease
debugging and accessing stuff:

* `./qareports dev list` lists all resources in the cluster, useful to discover pods
* `./qareports dev ssh master-node` ssh into the master node
* `./qareports dev ssh qareports-listener-deployment-947f8d9b8-ntfww` ssh into pod running `squad-listener`.
  * NOTE: be careful when running heavy commands on this pod, it's limited to a maximum of 512MB of RAM, but
    dont't worry it it crashes, Kubernetes scheduler will just removed crashed one and spawn a new one in no time!
* `./qareports dev logs -f deployment/qareports-web-deployment` gets the log stream of all pods under qareports-web deployment
* `./qareports dev k <kubectl-args>` run `kubectl` on development environment
* `./qareports dev k delete pod qareports-listener-deployment-947f8d9b8-ntfww` deletes a bad pod. If a pod crashes and
  Kubernetes didn't removed it (but it should've), it's useful to delete that pod so that forces creating a fresh new one.

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

# Dependencies

There are some tools necessary to manage qareports

* terraform: tool needed for managing resources on cloud like AWS, GKE
  `https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip`

* ansible: tool for automating node setup
  Install according to your distro: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

* kubectl: tool for managing kubernetes cluster
  `https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl`

* eksctl: official tool for creating a kubernetes cluster in AWS EKS
  `https://github.com/weaveworks/eksctl/releases/download/0.20.0/eksctl_Linux_amd64.tar.gz`


# NOTES

* Starting celery with '--without-mingle' prevented it from crashing everytime a
  new worker was started in parallel. More info: https://stackoverflow.com/questions/55249197/what-are-the-consequences-of-disabling-gossip-mingle-and-heartbeat-for-celery-w

# References

Posts that helped me A LOT understanding AWS Networking
https://nickcharlton.net/posts/terraform-aws-vpc.html and https://www.theguild.nl/cost-saving-with-nat-instances/#the-ec2-instance
