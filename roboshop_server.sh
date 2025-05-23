#!/bin/bash

# CONFIG
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-040ecf8bb247d6036"
ZONE_ID="Z08643193QT2QCZFDKUI1"
DOMAIN_NAME="tcloudguru.in"
INSTANCES=("mongodb" "catalogue" "user" "dispatch" "frontend" "payment" "shipping" "rabbitmq" "mysql" "cart" "redis")

# LOOP
#for instance in "${INSTANCES[@]}"
for instance in $@
do
  echo "Launching $instance..."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" --output text)

  aws ec2 wait instance-running --instance-ids $INSTANCE_ID

  PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
  PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

  if [ "$instance" == "frontend" ]; then
    RECORD_NAME="$instance.$DOMAIN_NAME"
    IP="$PUBLIC_IP"
  else
    RECORD_NAME="$instance.$DOMAIN_NAME"
    IP="$PRIVATE_IP"
  fi

  echo "$instance → Public IP: $PUBLIC_IP | Private IP: $PRIVATE_IP"

  aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch "{
    \"Comment\": \"DNS update for $RECORD_NAME\",
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$RECORD_NAME\",
        \"Type\": \"A\",
        \"TTL\": 60,
        \"ResourceRecords\": [{\"Value\": \"$IP\"}]
      }
    }]
  }"

  echo "$instance DNS record updated → $RECORD_NAME → $IP"
  echo "---------------------------------------------"
done
