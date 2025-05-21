#!/bin/bash

# Make sure AWS CLI is configured
# aws configure

# Define colors
r="\033[31m"
g="\033[32m"
y="\033[33m"
m="\033[36m"
s="\033[0m"

# Configuration variables
AMI_ID="ami-09c813fb71547fc4f"     # Replace with your AMI ID
SG_ID="sg-040ecf8bb247d6036"       # Replace with your actual Security Group ID
ZONE_ID="Z08643193QT2QCZFDKUI1"    # Replace with your actual Route 53 Hosted Zone ID
DOMAIN_NAME="tcloudguru.in"        # Replace with your domain name
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

# Launch the instances
echo -e "${y}⏳ Launching ${g}11${y} instances... This may take a little bit of time. Please wait.${s}"

for name in $@; #${INSTANCES[@]} //all instances at once
do
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

    # Determine which IP to assign to DNS
    if [ "$name" == "frontend" ]; 
    then
        DNS_IP="$PUBLIC_IP"
    else
        DNS_IP="$PRIVATE_IP"
    fi

    # Create DNS record for this instance
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${name}.${DOMAIN_NAME}\",
          \"Type\": \"A\",
          \"TTL\": 60,
          \"ResourceRecords\": [{
            \"Value\": \"${DNS_IP}\"
          }]
        }
      }]
    }"

    # Output the results with color
    echo -e "${g}Instance launched successfully:${s} $name"
    echo -e "${m}$name Private IP:${s} $PRIVATE_IP"
    echo -e "${m}$name Public IP:${s} $PUBLIC_IP"
    echo -e "${r}$name${s} : $DNS_IP"

done
