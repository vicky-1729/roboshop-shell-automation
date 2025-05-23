#!/bin/bash

# Exit on any error
set -e

# Color codes
r="\033[31m"   # Red
g="\033[32m"   # Green
y="\033[33m"   # Yellow
b="\033[34m"   # Blue
m="\033[35m"   # Magenta
reset="\033[0m"  # Reset

# Variables
USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo "$0" | cut -d '.' -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
S_DIR=$PWD

# Create log directory
mkdir -p "$LOGS_FOLDER"

# Root privilege check
if [ "$USERID" -ne 0 ]; then
    echo -e "${r}ERROR:: Please run this script with root access${reset}" | tee -a "$LOG_FILE"
    exit 1
fi

# Validation function
VALIDATE() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 ... ${g}SUCCESS${reset}" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... ${r}FAILURE${reset}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Node.js setup
dnf module disable nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Disabling existing Node.js module"

dnf module enable nodejs:20 -y &>> "$LOG_FILE"
VALIDATE $? "Enabling Node.js 20 module"

dnf install nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Installing Node.js 20"

# roboshop user setup
if id roboshop &>/dev/null; then
    echo -e "roboshop user is ${g}already created${y} ... skipping${reset}" | tee -a "$LOG_FILE"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOG_FILE"
    VALIDATE $? "Creating roboshop system user"
fi

# Application setup
mkdir -p /app &>> "$LOG_FILE"
VALIDATE $? "Creating /app directory"

rm -rf /app/* &>> "$LOG_FILE"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading catalogue.zip"

cd /app
unzip /tmp/catalogue.zip &>> "$LOG_FILE"
VALIDATE $? "Unzipping catalogue.zip"

npm install &>> "$LOG_FILE"
VALIDATE $? "Installing Node.js dependencies"

# Service setup
cp $S_DIR/service/catalogue.service /etc/systemd/system/catalogue.service &>> "$LOG_FILE"
VALIDATE $? "Copying catalogue service file"

systemctl daemon-reload &>> "$LOG_FILE"
VALIDATE $? "Reloading systemd"

systemctl enable catalogue &>> "$LOG_FILE"
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue &>> "$LOG_FILE"
VALIDATE $? "Starting catalogue service"

# MongoDB client setup
cp $S_DIR/repo_config/mongo.repo /etc/yum.repos.d/mongodb.repo &>> "$LOG_FILE"
VALIDATE $? "Copying MongoDB repo file"

dnf install mongodb-mongosh -y &>> "$LOG_FILE"
VALIDATE $? "Installing MongoDB shell"

# Load data into MongoDB if not already present
STATUS=$(mongosh --host mongodb.tcloudguru.in --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ "$STATUS" -lt 0 ]; then
    mongosh --host mongodb.tcloudguru.in </app/db/master-data.js &>> "$LOG_FILE"
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... ${y}SKIPPING${reset}" | tee -a "$LOG_FILE"
fi
