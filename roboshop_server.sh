#!/bin/bash

set -e

# Color codes
r="\033[31m"   # Red
g="\033[32m"   # Green
y="\033[33m"   # Yellow
b="\033[34m"   # Blue
m="\033[35m"   # Magenta
reset="\033[0m"  # Reset

# CONFIG
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-040ecf8bb247d6036"
ZONE_ID="Z08643193QT2QCZFDKUI1"
DOMAIN_NAME="tcloudguru.in"

for instance in "$@"; do
  echo -e "Launching ${y}${instance}...${reset}"
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" --output text)

  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  PRIVATE_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
  PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

  RECORD_NAME="${instance}.${DOMAIN_NAME}"
  if [ "$instance" == "frontend" ]; then
    IP="$PUBLIC_IP"
  else
    IP="$PRIVATE_IP"
  fi

  echo -e "$instance → ${g}Public IP:${reset} $PUBLIC_IP | ${g}Private IP:${reset} $PRIVATE_IP"

  aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "{
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

  echo -e "${y}$instance DNS record updated → ${r}$RECORD_NAME → ${g}$IP${reset}"
  echo -e "${reset}-------------------------------------------------------------------${reset}"
done
