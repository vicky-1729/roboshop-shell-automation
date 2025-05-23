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

# roboshop cart setup
if id roboshop &>/dev/null; then
    echo -e "roboshop cart is ${g}already created${y} ... skipping${reset}" | tee -a "$LOG_FILE"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system cart" roboshop &>> "$LOG_FILE"
    VALIDATE $? "Creating roboshop system cart"
fi

# Application setup
mkdir -p /app &>> "$LOG_FILE"
VALIDATE $? "Creating /app directory"

rm -rf /app/* &>> "$LOG_FILE"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading cart.zip"

cd /app
unzip /tmp/cart.zip &>> "$LOG_FILE"
VALIDATE $? "Unzipping cart.zip"

npm install &>> "$LOG_FILE"
VALIDATE $? "Installing Node.js dependencies"

# Service setup
cp $S_DIR/service/cart.service /etc/systemd/system/cart.service &>> "$LOG_FILE"
VALIDATE $? "Copying cart service file"

systemctl daemon-reload &>> "$LOG_FILE"
VALIDATE $? "Reloading system"

systemctl enable cart &>> "$LOG_FILE"
VALIDATE $? "Enabling cart service"

systemctl start cart &>> "$LOG_FILE"
VALIDATE $? "Starting cart service"
