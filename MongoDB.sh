#!/bin/bash

# Color codes
r="\e[31m"   # Red
g="\e[32m"   # Green
y="\e[33m"   # Yellow
m="\e[36m"   # Cyan
s="\e[0m"    # Reset

# Check whether the user is root or not
if [ "$(id -u)" -eq 0 ]; then
    echo -e "You are a ${r}root${s} user. You can directly run the script."
else
    echo -e "You are not a ${r}root user${s}. Please run the script with ${r}sudo${s}."
    exit 1
fi

# Log folder setup
LOG_FOLDER="/var/log/roboshop-logs"  # Log directory path
SCRIPT_NAME=$(basename "$0" .sh)     # Extract script name without .sh extension
LOG_FILES="${LOG_FOLDER}/${SCRIPT_NAME}.log"  # Full log file path

# Create the log folder if it doesn't exist
mkdir -p $LOG_FOLDER
echo -e "${y}Printing the current time: $(date)${s}"  # Print timestamp

# Validation function
validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 is ${g}success!${s}" | tee -a "$LOG_FILES"
    else
        echo -e "$2 is ${r}failed!${s}" | tee -a "$LOG_FILES"
        exit 1
    fi
}

# Begin installation steps

# Step 1: Copy MongoDB repo file
echo -e "${y}Creating MongoDB repo file...${s}"
cp repos/mongo.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILES
validate $? "Creating MongoDB repo file"

# Step 2: Install MongoDB
echo -e "${y}Installing MongoDB...${s}"
dnf install mongodb-org -y &>>$LOG_FILES
validate $? "Installing MongoDB"

# Step 3: Enable MongoDB to start on boot
echo -e "${y}Enabling MongoDB to start on boot...${s}"
systemctl enable mongod &>>$LOG_FILES
validate $? "Enabling MongoDB"

# Step 4: Start MongoDB service
echo -e "${y}Starting MongoDB service...${s}"
systemctl start mongod &>>$LOG_FILES
validate $? "Starting MongoDB"

# Step 5: Update MongoDB config file to allow external connections
echo -e "${y}Updating MongoDB config to allow connections from all IPs...${s}"
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>>$LOG_FILES
validate $? "Updating MongoDB config file"

# Step 6: Restart MongoDB service to apply changes
echo -e "${y}Restarting MongoDB service...${s}"
systemctl restart mongod &>>$LOG_FILES
validate $? "Restarting MongoDB"

# Final message
echo -e "${m}MongoDB ${g}installation and setup completed successfully${s}"
