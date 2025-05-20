#!/bin/bash

# Configuration
AMI_ID="ami-09c813fb71547fc4f"   # Replace with your AMI ID
SG_ID="sg-01bc7ebe005fb1cb2"     # Replace with your actual Security Group ID
ZONE_ID="Z032558618100M4EJX8X4"  # Replace with your actual Route 53 Hosted Zone ID
DOMAIN_NAME="daws84s.site"       # Replace with your domain name
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

# Loop through each instance name
for instance in "${INSTANCES[@]}";
 do
    echo "Launching instance: $instance"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    if [ -z "$INSTANCE_ID" ]; then
        echo "Failed to launch instance: $instance"
        continue
    fi

    echo "Waiting for instance $INSTANCE_ID to be in running state..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
    fi

    echo "$instance IP address: $IP"

    # Update DNS record in Route 53
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
            \"Comment\": \"Updating DNS for $instance\",
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$instance.$DOMAIN_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 60,
                    \"ResourceRecords\": [{\"Value\": \"$IP\"}]
                }
            }]
        }"

    echo "DNS record updated for $instance.$DOMAIN_NAME -> $IP"
    echo "---------------------------------------------"
done
