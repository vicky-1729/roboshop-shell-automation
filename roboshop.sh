#!/bin/bash

# Make sure AWS CLI is configured
# aws configure

# Define colors
r="\033[31m"   # Red
g="\033[32m"   # Green
y="\033[33m"   # Yellow
m="\033[36m"   # Cyan
s="\033[0m"    # Reset

# Configuration variables
AMI_ID="ami-09c813fb71547fc4f"     # Replace with your AMI ID
SG_ID="sg-040ecf8bb247d6036"       # Replace with your actual Security Group ID
ZONE_ID="Z08643193QT2QCZFDKUI1"    # Replace with your actual Route 53 Hosted Zone ID
DOMAIN_NAME="tcloudguru.in"        # Replace with your domain name
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")  # List of services to launch

# Inform the user that instance creation has started
echo -e "${y}⏳ Launching ${g}instances... This may take a little bit of time. Please wait.${s}"

# Loop through all services passed as arguments
for name in $@; #${INSTANCES[@]} //all instances at once
do
    # Launch EC2 instance with given tags and config
    INSTANCE_ID=$(aws ec2 run-instances \
      --image-id "$AMI_ID" \
      --instance-type t2.micro \
      --security-group-ids "$SG_ID" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
      --query 'Instances[0].InstanceId' \
      --output text)

    if [ "$?" -eq 0 ]
    then
      echo -e "$name:${m}Instance launched ${g}successfully:${s} "
    else
       echo -e "$name:${m}Instance launched ${r}failure:${s} "
       exit 1
    fi
    # Wait until the instance state becomes "running"
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    
   

    # Get the private IP of the instance
    PRIVATE_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)

    # Get the public IP of the instance
    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)

    # Use public IP for frontend, private IP for backend/internal services
    if [ "$name" == "frontend" ]; 
    then
        DNS_IP="$PUBLIC_IP"
    else
        DNS_IP="$PRIVATE_IP"
    fi

    # Create/Update Route 53 DNS record
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${name}.${DOMAIN_NAME}\",
          \"Type\": \"A\",
          \"TTL\": 1,
          \"ResourceRecords\": [{
            \"Value\": \"${DNS_IP}\"
          }]
        }
      }]
    }"

    # Display instance launch result
    
    echo -e "${m}$name Private IP:${s} $PRIVATE_IP"
    echo -e "${m}$name Public IP:${s} $PUBLIC_IP"
    echo -e "${r}$name${s} : $DNS_IP"

done
