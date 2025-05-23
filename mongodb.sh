#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Color codes
r="\033[31m"   # Red
g="\033[32m"   # Green
y="\033[33m"   # Yellow
b="\033[34m"   # Blue
m="\033[35m"   # Magenta
reset="\033[0m"  # Reset

# Define log folder and file
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$( echo $0 | cut -d '.' -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
S_DIR="$PWD"

# Create log folder if it doesn't exist
mkdir -p "$LOG_FOLDER"

# Check if the script is being run as the root user
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${g}✔ Running as root user.${reset}" | tee -a "$LOG_FILE"
else
    echo -e "${r}✖ Error:${reset} This script must be run as root. Please use sudo or switch to the root user." | tee -a "$LOG_FILE"
    exit 1
fi

# Function to validate the exit status of commands and print appropriate messages
VALIDATE() {
    if [ "$1" -eq 0 ]; then
        echo -e "${g}✔ $2 succeeded.${reset}" | tee -a "$LOG_FILE"
    else
        echo -e "${r}✖ $2 failed.${reset}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Copy MongoDB repo file
cp "$S_DIR/mongodb.repo" /etc/yum.repos.d/mongodb.repo &>> "$LOG_FILE"
VALIDATE $? "Copying MongoDB repo file"

# Install MongoDB
dnf install mongodb-org -y &>> "$LOG_FILE"
VALIDATE $? "Installing mongodb server"

# Enable MongoDB service
systemctl enable mongod &>> "$LOG_FILE"
VALIDATE $? "Enabling mongodb service"

# Start MongoDB service
systemctl start mongod &>> "$LOG_FILE"
VALIDATE $? "Starting mongodb server"

# Check MongoDB service status
systemctl status mongod | grep Active &>> "$LOG_FILE"
VALIDATE $? "Checking mongodb server is running"

# Update MongoDB config to allow external connections
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>> "$LOG_FILE"

# Restart MongoDB service
systemctl restart mongod &>> "$LOG_FILE"
VALIDATE $? "Restarting mongodb server"
