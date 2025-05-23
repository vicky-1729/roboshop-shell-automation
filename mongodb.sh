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

# Create log directory if it doesn't exist
mkdir -p $LOGS_FOLDER

# Check for root privileges
if [ $USERID -ne 0 ]; then
    echo -e "${r}ERROR:: Please run this script with root access${reset}"
    exit 1
fi


# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... ${g}SUCCESS${reset}" | tee -a $LOG_FILE
    else
        echo -e "$2 ... ${r}FAILURE${reset}" | tee -a $LOG_FILE
        exit 1
    fi
}

# Set script directory
S_DIR=$(dirname "$0")

# MongoDB setup
cp $S_DIR/repo_config/mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
VALIDATE $? "Copying MongoDB repo file"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing MongoDB server"

systemctl enable mongod &>> $LOG_FILE
systemctl start mongod &>> $LOG_FILE
VALIDATE $? "Starting MongoDB server"

systemctl status mongod | grep Active &>> $LOG_FILE
VALIDATE $? "Checking MongoDB server status"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>> $LOG_FILE
VALIDATE $? "Updating bind IP in mongod.conf"

systemctl restart mongod &>> $LOG_FILE
VALIDATE $? "Restarting MongoDB server"
