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
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILES="$LOG_FOLDER/$SCRIPT_NAME.log"
script_dir=$PWD

# Making directory for logs
mkdir -p "$LOG_FOLDER"

# Function to validate each step with success/failure message
validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 is ${g}success ...!${s}" | tee -a "$LOG_FILES"
    else
        echo -e "$2 is ${r}failure ...!${s}" | tee -a "$LOG_FILES"
        exit 1
    fi
}

# Disable default Redis module
echo -e "${y}Disabling Redis module...${s}"

dnf module disable redis -y &>> "$LOG_FILES"
validate $? "Redis disabling"

# Enable Redis 7 module
echo -e "${y}Enabling Redis:7 module...${s}"

dnf module enable redis:7 -y &>> "$LOG_FILES"
validate $? "Redis:7 enabling"

# Install Redis
echo -e "${y}Installing Redis...${s}"

dnf install redis -y &>> "$LOG_FILES"
validate $? "Redis installation"

# Update Redis config to allow external connections
echo -e "${y}Updating Redis configuration 127.0.0.0. to 0.0.0.0 ...${s}"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/redis/redis.conf &>> "$LOG_FILES"
validate $? "Redis config update"

# Enable Redis service
echo -e "${y}Enabling Redis service...${s}"

systemctl enable redis &>> "$LOG_FILES"
validate $? "Redis service enable"

# Start Redis service
echo -e "${y}Starting Redis service...${s}"

systemctl start redis &>> "$LOG_FILES"
validate $? "Redis service start"

# Final message
echo -e "${m}Redis setup completed successfully..!${s}"
