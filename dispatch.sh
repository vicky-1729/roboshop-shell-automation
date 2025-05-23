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


dnf install golang -y &>> "$LOG_FILE"
VALIDATE $? "Installing golang"


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

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading dispatch.zip"

cd /app
unzip /tmp/dispatch.zip &>> "$LOG_FILE"
VALIDATE $? "Unzipping dispatch.zip"

# install dependencies
go mod init dispatch &>> "$LOG_FILE"
go get &>> "$LOG_FILE"
go build &>> "$LOG_FILE"

VALIDATE $? " doing init,get,build process"

cp $S_DIR/service/dispatch.service /etc/systemd/system/dispatch.service &>> "$LOG_FILE"
VALIDATE $? "dispatch service creation"

systemctl daemon-reload
VALIDATE $? "system-reloaded"

systemctl enable dispatch 
systemctl start dispatch
VALIDATE $? "dispatch service "