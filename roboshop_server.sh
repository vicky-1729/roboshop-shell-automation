#!/bin/bash

#color codes
r="\e[31m"
g="\e[32m"
y="\e[33m"
b="\e[34m"
m="\e[35m"
s="\e[37m"

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
  echo -e "Launching ${b}$instance...${s}"
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

  echo "$instance → ${r}Public IP:${s} $PUBLIC_IP | ${r}Private IP:${s} $PRIVATE_IP"

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

  echo "${y}$instance DNS record updated → ${r}$RECORD_NAME → ${g}$IP${s}"
  echo "---------------------------------------------"
done
