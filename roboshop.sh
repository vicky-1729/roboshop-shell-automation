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
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-040ecf8bb247d6036"
ZONE_ID="Z08643193QT2QCZFDKUI1"
DOMAIN_NAME="tcloudguru.in"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

# Use arguments if provided, else default to all
if [ "$#" -gt 0 ]; then
  TARGET_INSTANCES=("$@")
else
  TARGET_INSTANCES=("${INSTANCES[@]}")
fi

# Launch message
echo -e "${y}⏳ Launching ${g}${#TARGET_INSTANCES[@]}${y} instance(s)... Please wait.${s}"

for name in "${TARGET_INSTANCES[@]}"
do
    echo -e "${y}🔹 Launching instance: $name${s}"

    INSTANCE_ID=$(aws ec2 run-instances \
      --image-id "$AMI_ID" \
      --instance-type t2.micro \
      --security-group-ids "$SG_ID" \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
      --query 'Instances[0].InstanceId' \
      --output text)

    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    PRIVATE_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)

    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)

    if [ "$name" == "frontend" ]; then
        DNS_IP="$PUBLIC_IP"
    else
        DNS_IP="$PRIVATE_IP"
    fi

    # Create change batch JSON dynamically
    cat > /tmp/${name}_dns_record.json <<EOF
{
  "Comment": "Creating/updating record for $name",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$name.$DOMAIN_NAME",
      "Type": "A",
      "TTL": 60,
      "ResourceRecords": [{
        "Value": "$DNS_IP"
      }]
    }
  }]
}
EOF

    aws route53 change-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --change-batch file:///tmp/${name}_dns_record.json

    echo -e "${g}✅ Instance launched:${s} $name"
    echo -e "${m}🔐 Private IP:${s} $PRIVATE_IP"
    echo -e "${m}🌍 Public IP :${s} $PUBLIC_IP"
    echo -e "${r}🔗 DNS Record:${s} $name.$DOMAIN_NAME -> $DNS_IP"
    echo -e "${y}--------------------------------------${s}"

done
