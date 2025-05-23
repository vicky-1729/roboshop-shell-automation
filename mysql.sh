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

# mysqld setup



dnf install mysql-server -y &>> "$LOG_FILE"
VALIDATE $? "Installing mysqld "

systemctl enable mysqld &>> "$LOG_FILE"
VALIDATE $? "Enabling mysqld service"

systemctl start mysqld &>> "$LOG_FILE"
VALIDATE $? "Starting mysqld service"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "mysqld password status creating "