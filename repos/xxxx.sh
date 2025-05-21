#!/bin/bash

# Configuration
AMI_ID="ami-09c813fb71547fc4f"   # Replace with your AMI ID
SG_ID="sg-01bc7ebe005fb1cb2"     # Replace with your actual Security Group ID
ZONE_ID="Z032558618100M4EJX8X4"  # Replace with your actual Route 53 Hosted Zone ID
DOMAIN_NAME="daws84s.site"       # Replace with your domain name
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

#creating the EC2-instance

   aws ec2 run-instances \
       --image-id ami-09c813fb71547fc4f \
       --instance-type t2.mirco \
       --security-group-ids sg-01bc7ebe005fb1cb2 \
       --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=My-instance}]"

    