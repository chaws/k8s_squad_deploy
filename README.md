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

# Lessons learned

While learning k8s, some things always worked but some just broke for a reason.
This section is intended to describe weird behaviors and how to fix, or at least
start debugging.

## Pod didn't start properly

There are a lot of reasons why a pod won't start:
* the image doesn't exist
* there's nowhere or not enough computer power available to deploy it
  * staging and production pods are supposed to be scheduled under AWS Fargate, and that happens only if you're deploying the pods under the correct namespace

Usually a command to describe what is going on on a pod is

```
./qareports dev describe pod pod-name
```

## Emails

I always find it frustrating to understand how emails work so I wanted to make it clear to show how the mechanics of
emails work for this deploy.

We're currently using AWS Simple Email Service aka SES to send emails. There's a whole page with that in the AWS console.
It doesn't really require any activation to start using it. On an account that SES was never used, AWS put it under sandbox
mode, for security. This way SES will send emails to only verified ones. The daily quota is very reduced. For production
use, you NEED to create a support ticket in AWS asking them to move out of sandbox mode. I won't cover the details here because
there's a nice documentagion page in AWS website about that.

Once things are cleared in SES, there are 2 ways of use it to send emails: as an SMTP relay or as RESTfull API. We're using the 
second one for convenience. It's super-super easy to make it work. You just spin up a docker container from https://github.com/blueimp/aws-smtp-relay
and it proxies all email requests to SES. I didn't go into the internals of this docker image, but it's very tiny.

In this deploy, there's a service running aws-smtp-relay container under kube-system namespace. Pods running in this namespace
run on an EC2 node created for running k8s stuff, while application pods run under Fargate nodes. Initially I had made this
container run in qareports-worker pod, but the node where the aws-smtp-relay is running needs to have SES IAM policy
in order to authenticate to SES. Until date (Jun/2020) I couldn't find a way of doing this mainly because Fargate nodes
are serverless, so it's like black magic how they make this happen. A workaround was to place aws-smtp-relay in a node
where I could attach necessary SES policies to make email usage possible.

The two settings to handle EMAIL are `SQUAD_EMAIL_HOST` and `SQUAD_EMAIL_PORT`, which should point to the aws-smtp-relay service.

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
