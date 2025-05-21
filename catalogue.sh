#!/bin/bash

# Color codes
r="\e[31m"   # Red
g="\e[32m"   # Green
y="\e[33m"   # Yellow
m="\e[36m"   # Cyan 
s="\e[0m"    # Reset

# Check whether the user is root or not
if [ $(id -u) -eq 0 ]; then
    echo -e "You are a ${m}root user${s}, you can directly run the script."
else
    echo -e "You are ${r}not a root user${s}, please run the script using sudo."
    exit 1
fi

# Log folder setup
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
LOG_FILES="$LOG_FOLDER/$SCRIPT_NAME.log"
script_dir=$PWD

# Making directory
mkdir -p "$LOG_FOLDER"

# Function to validate each step
validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "${g}$2 is success ...!${s}" | tee -a "$LOG_FILES"
    else
        echo -e "${r}$2 is failure ...!${s}" | tee -a "$LOG_FILES"
    fi
}

echo -e "${y}Disabling NodeJS module...${s}"
dnf module disable nodejs -y &>> "$LOG_FILES"
validate $? "NodeJS disabling"

echo -e "${y}Enabling NodeJS:20 module...${s}"
dnf module enable nodejs:20 -y &>> "$LOG_FILES"
validate $? "NodeJS:20 enabling"

echo -e "${y}Installing NodeJS...${s}"
dnf install nodejs -y &>> "$LOG_FILES"
validate $? "NodeJS installation"

# Add application user
id roboshop &>> "$LOG_FILES"
if [ $? -ne 0 ]; then
    echo -e "${y}Adding user for roboshop...${s}"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Roboshop user creation"
else
    echo -e "${g}User 'roboshop' already exists. Skipping user creation.${s}"
fi

mkdir -p /app
validate $? "App folder creation"

rm -rf /app/*
echo -e "${y}Downloading the catalogue zip file...${s}"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> "$LOG_FILES"
validate $? "Downloading catalogue zip"

cd /app

echo -e "${y}Unzipping the catalogue zip file...${s}"
unzip /tmp/catalogue.zip &>> "$LOG_FILES"
validate $? "Unzipping catalogue zip"

echo -e "${y}Installing dependencies...${s}"
npm install &>> "$LOG_FILES"
validate $? "Dependencies installation"

echo -e "${y}Creating service for catalogue...${s}"
cp "$script_dir/services/catalogue.service" /etc/systemd/system/catalogue.service &>> "$LOG_FILES"
validate $? "Catalogue service creation"

echo -e "${y}Starting the catalogue service...${s}"
systemctl daemon-reload
systemctl enable catalogue &>> "$LOG_FILES"
systemctl start catalogue &>> "$LOG_FILES"
validate $? "Catalogue service start"

echo -e "${y}Creating MongoDB repo file...${s}"
cp "$script_dir/repos/mongo.repo" /etc/yum.repos.d/mongodb.repo &>> "$LOG_FILES"
validate $? "MongoDB repo added"

echo -e "${y}Installing MongoDB client...${s}"
dnf install mongodb-mongosh -y &>> "$LOG_FILES"
validate $? "MongoDB client installation"

STATUS=$(mongosh --host mongodb.tcloudguru.in --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ "$STATUS" -lt 0 ]; then
    echo -e "${y}Loading data into MongoDB...${s}"
    mongosh --host mongodb.tcloudguru.in </app/db/master-data.js &>> "$LOG_FILES"
    validate $? "Loading data into MongoDB"
else
    echo -e "${g}Data is already loaded ... ${y}SKIPPING${s}"
fi

echo "$m catalogue part completed"