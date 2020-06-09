#!/usr/bin/env python3

#
#  This file uses terraform state to pick up the following items necessary for k8s setup:
#  * VPC and Subnets ids and cidr blocks
#  * Database credentials
#  * RabbitMQ private IP address
#

import json
import yaml
import os
import sys


state = json.loads(sys.stdin.read())

# Force update of secrets
db_host = None
mq_host = None

# Force update of cluster settings (require destruction)
vpc_id = None
vpc_cidr = None

subnets = {
    'public': {'1': {'id': None, 'cidr': None, 'az': None}, '2': {'id': None, 'cidr': None, 'az': None}},
    'private': {'1': {'id': None, 'cidr': None, 'az': None}, '2': {'id': None, 'cidr': None, 'az': None}},
}

for module in state['modules']:
    for resource_name, resource in module['resources'].items():
        if not db_host and 'aws_db_instance.qareports_db_instance' == resource_name:
            db_host = resource['primary']['attributes']['address']

        if not mq_host and 'aws_instance.qareports_mq_instance' == resource_name:
            mq_host = resource['primary']['attributes']['private_ip']
        
#        if 'aws_vpc.qareports_vpc' == resource_name:
#            vpc_id = resource['primary']['attributes']['id']
#            vpc_cidr = resource['primary']['attributes']['cidr_block']
#
#        for subnet in subnets.keys():
#            for _id in subnets[subnet].keys():
#                subnet_name = 'aws_subnet.qareports_%s_subnet_%s' % (subnet, _id)
#                if  subnet_name == resource_name:
#                    subnets[subnet][_id]['id'] = resource['primary']['attributes']['id']
#                    subnets[subnet][_id]['cidr'] = resource['primary']['attributes']['cidr_block']
#                    subnets[subnet][_id]['az'] = resource['primary']['attributes']['availability_zone']

print('db_host: %s' % db_host)
print('mq_host: %s' % mq_host)

# print('vpc: %s %s' % (vpc_id, vpc_cidr))
# print('subnets: %s' % subnets)
# 
# # Update k8s/cluster.yml
# root_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), '../..')
# cluster_filename = r'%s/k8s/cluster.yml' % root_dir
# with open(cluster_filename, 'r') as f:
#     cluster = yaml.load(f, Loader=yaml.FullLoader)
# 
# cluster['vpc']['id'] = vpc_id
# cluster['vpc']['cidr'] = vpc_cidr
# for subnet in subnets.keys():
#     for _id in subnets[subnet].keys():
#         az = subnets[subnet][_id]['az']
#         cluster['vpc']['subnets'][subnet][az] = {
#             'id': subnets[subnet][_id]['id'],
#             'cidr': subnets[subnet][_id]['cidr']
#         }
# 
# with open(cluster_filename, 'w') as f:
#     yaml.dump(cluster, f, default_flow_style=False)
