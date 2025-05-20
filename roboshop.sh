#!/bin/bash

#create access key and secret key in aws
#make sure aws configure

# Configuration variables

AMI_ID="ami-09c813fb71547fc4f"   # Replace with your AMI ID
SG_ID="sg-040ecf8bb247d6036"     # Replace with your actual Security Group ID
ZONE_ID="Z08643193QT2QCZFDKUI1"  # Replace with your actual Route 53 Hosted Zone ID
DOMAIN_NAME="tcloudguru.in"      # Replace with your domain name
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

aws ec2 run-instances \
  --image-id ${AMI_ID} \                        # Replace with valid AMI ID
  --instance-type t2.micro \
  --security-groups ${SG_ID}\         # Replace with your security group
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyInstance}]' \
  --count 1
echo "instance launched successfully ${MyInstance}"