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
dnf module disable nginx -y &>> "$LOG_FILE"
VALIDATE $? "Disabling existing nginx module"

dnf module enable nginx:1.24 -y &>> "$LOG_FILE"
VALIDATE $? "Enabling nginx:1.24 module"

dnf install nginx -y &>> "$LOG_FILE"
VALIDATE $? "Installing nginx:1.24"

systemctl enable nginx  &>> "$LOG_FILE"
VALIDATE $? "Enabling nginx service"

systemctl start nginx &>> "$LOG_FILE"
VALIDATE $? "Starting nginx service"


rm -rf /usr/share/nginx/html/* &>> "$LOG_FILE"
VALIDATE $? "removed default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> "$LOG_FILE"
VALIDATE $? "downloading the frontend zip file"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>> "$LOG_FILE"
VALIDATE $? "unzipping the frontend file"

cp $S_DIR/repo_config/nginx.conf /etc/nginx/nginx.conf &>> "$LOG_FILE"
VALIDATE $? "nginx configuration "

systemctl restart nginx &>> "$LOG_FILE"
VALIDATE $? "restarting nginx service"

