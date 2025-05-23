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


cp repo_config/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> "LOG_FILE"
VALIDATE $? "rabbitMQ repo adding"


dnf install rabbitmq-server -y &>> "LOG_FILE"
VALIDATE $? "Installing rabbitMQ-server"

systemctl enable rabbitmq-server &>> "LOG_FILE"
VALIDATE $? "enabling rabbitMQ"

systemctl start rabbitmq-server &>> "LOG_FILE"
VALIDATE $? "starting rabbitMQ"


rabbitmqctl add_user roboshop roboshop123 &>> "LOG_FILE"
VALIDATE $? "adding of roboshop user and group "

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> "LOG_FILE"
VALIDATE $? "added permission "