#!/bin/bash

#create access key and secret key in aws
#make sure aws configure


# Configuration variables
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-040ecf8bb247d6036"
ZONE_ID="Z08643193QT2QCZFDKUI1"
DOMAIN_NAME="tcloudguru.in"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --security-group-ids "$SG_ID" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyInstance}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance launched successfully: $INSTANCE_ID"
# Get IPs from EC2 describe-instances
PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

# Print them with labels
echo "Private IP: $PRIVATE_IP"
echo "Public IP: $PUBLIC_IP"

