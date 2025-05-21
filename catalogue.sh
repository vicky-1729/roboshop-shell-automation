#!/bin/bash

# Color codes
r="\e[31m"   # Red
g="\e[32m"   # Green
y="\e[33m"   # Yellow
m="\e[36m"   # Cyan 
s="\e[0m"    # Reset

# Exit if any command fails
set -e

# Check for root user
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${r}You are not a root user${s}. Please run the script using sudo."
    exit 1
else
    echo -e "${g}You are a root user${s}. Proceeding with the setup..."
fi

# Log and script setup
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
TIMESTAMP=$(date +%F-%T)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
SCRIPT_DIR=$PWD

mkdir -p "$LOGS_FOLDER"

# Validation function
validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "${g}$2 - SUCCESS${s}" | tee -a "$LOG_FILE"
    else
        echo -e "${r}$2 - FAILED${s}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

echo -e "${y}Disabling default NodeJS...${s}"
dnf module disable nodejs -y &>>"$LOG_FILE"
validate $? "NodeJS disabled"

echo -e "${y}Enabling NodeJS 20...${s}"
dnf module enable nodejs:20 -y &>>"$LOG_FILE"
validate $? "NodeJS 20 enabled"

echo -e "${y}Installing NodeJS...${s}"
dnf install nodejs -y &>>"$LOG_FILE"
validate $? "NodeJS installed"

echo -e "${y}Creating roboshop user if it doesn't exist...${s}"
id roboshop &>>"$LOG_FILE" || useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "roboshop user setup"

echo -e "${y}Creating /app directory...${s}"
mkdir -p /app &>>"$LOG_FILE"
validate $? "/app directory created"

echo -e "${y}Downloading catalogue zip...${s}"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>"$LOG_FILE"
validate $? "Catalogue zip downloaded"

echo -e "${y}Extracting application files...${s}"
cd /app
unzip -o /tmp/catalogue.zip &>>"$LOG_FILE"
validate $? "Catalogue extracted"

echo -e "${y}Installing application dependencies...${s}"
npm install &>>"$LOG_FILE"
validate $? "Dependencies installed"

echo -e "${y}Setting up systemd service...${s}"
cp "$SCRIPT_DIR/services/catalogue.service" /etc/systemd/system/catalogue.service &>>"$LOG_FILE"
validate $? "Catalogue service file copied"

systemctl daemon-reload &>>"$LOG_FILE"
systemctl enable catalogue &>>"$LOG_FILE"
systemctl restart catalogue &>>"$LOG_FILE"
validate $? "Catalogue service started"

echo -e "${y}Configuring MongoDB repo...${s}"
cp "$SCRIPT_DIR/repos/mongo.repo" /etc/yum.repos.d/mongodb.repo &>>"$LOG_FILE"
validate $? "MongoDB repo configured"

echo -e "${y}Installing MongoDB shell...${s}"
dnf install mongodb-mongosh -y &>>"$LOG_FILE"
validate $? "MongoDB shell installed"

echo -e "${y}Loading data into MongoDB...${s}"
mongosh --host mongodb.tcloudguru.in </app/db/master-data.js &>>"$LOG_FILE"
validate $? "Data loaded into MongoDB"

echo -e "${y}Testing MongoDB connection...${s}"
mongosh --host mongodb.tcloudguru.in --eval "db.stats()" &>>"$LOG_FILE"
validate $? "MongoDB connection verified"

echo -e "${g}All steps completed successfully.${s}"
echo -e "Log file location: ${m}$LOG_FILE${s}"
