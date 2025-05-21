#!/bin/bash
# make sure that aws configured in the server or not

# Configuration variables
AMI_ID="ami-09c813fb71547fc4f"     # Replace with your AMI ID
SG_ID="sg-040ecf8bb247d6036"       # Replace with your actual Security Group ID
ZONE_ID="Z08643193QT2QCZFDKUI1"    # Replace with your actual Route 53 Hosted Zone ID
DOMAIN_NAME="tcloudguru.in"        # Replace with your domain name
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")


#create and launch instances
for instance in "${INSTANCES[@]}"
do
    InstanceId=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type t2.mirco\
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$instance}]' \
    -- output-text)
   
     if [ "$InstanceId" == "frontend" ]
     then
       IP=$(aws ec2 describe-instances --instance-ids ${InstanceId} --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
     else
       IP=$(aws ec2 describe-instances --instance-ids ${InstanceId} --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
     fi
  
  
  echo "${InstanceId} instance is launched successfully"
     
     {
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "${InstanceId}.${DOMAIN_NAME}",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "$IP"
                }
                ]
            }
            }
        ]
     }
    echo "${InstanceId}:${IP} instance is launched successfully"


 done