#!/bin/bash

# Make sure AWS CLI is configured
# aws configure

# Configuration variables
AMI_ID="ami-09c813fb71547fc4f"     # Replace with your AMI ID
SG_ID="sg-040ecf8bb247d6036"       # Replace with your actual Security Group ID
ZONE_ID="Z08643193QT2QCZFDKUI1"    # Replace with your actual Route 53 Hosted Zone ID
DOMAIN_NAME="tcloudguru.in"        # Replace with your domain name
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

# Launch the instances
for name in "${INSTANCES[@]}"; do
    # Launch EC2 instance
    INSTANCE_ID=$(aws ec2 run-instances \
      --image-id "$AMI_ID" \
      --instance-type t2.micro \
      --security-group-ids "$SG_ID" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
      --query 'Instances[0].InstanceId' \
      --output text)

    # Wait until the instance is running
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    # Fetch public and private IPs
    PRIVATE_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)

    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)

    # Output the results
    echo "Instance launched successfully: $name"
    echo " $name Private IP: $PRIVATE_IP"
    echo " $name Public IP: $PUBLIC_IP"
done
