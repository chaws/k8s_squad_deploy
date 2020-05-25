#!/bin/sh

# Turns a machine into a NAT instance
# ref: https://www.theguild.nl/cost-saving-with-nat-instances/#the-ec2-instance
sysctl -w net.ipv4.ip_forward=1
/sbin/iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
