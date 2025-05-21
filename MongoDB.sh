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
log_folder="/var/log/roboshop-logs"  # Use absolute path
script_name=$(basename "$0" .sh)      # Extract the script name without extension
log_files="${log_folder}/${script_name}.log"

# Create the log folder if it doesn't exist
mkdir -p $log_folder

# Validation function
validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 is ${g}success!${s}" | tee -a "$log_files"
    else
        echo -e "$2 is ${r}failed!${s}" | tee -a "$log_files"
        exit 1
    fi
}

# Begin installation steps

# Step 1: Copy MongoDB repo file
echo -e "Creating MongoDB repo file..."
cp repos/mongo.repo /etc/yum.repos.d/mongodb.repo &>>$log_files
validate $? "Creating MongoDB repo file"

# Step 2: Install MongoDB
echo -e "Installing MongoDB..."
dnf install mongodb-org -y &>>$log_files
validate $? "Installing MongoDB"

# Step 3: Enable MongoDB to start on boot
echo -e "Enabling MongoDB to start on boot..."
systemctl enable mongod &>>$log_files
validate $? "Enabling MongoDB"

# Step 4: Start MongoDB service
echo -e "Starting MongoDB service..."
systemctl start mongod &>>$log_files
validate $? "Starting MongoDB"

# Step 5: Update MongoDB config file to allow external connections
echo -e "Updating MongoDB config to allow connections from all IPs..."
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>>$log_files
validate $? "Updating MongoDB config file"

# Step 6: Restart MongoDB service to apply changes
echo -e "Restarting MongoDB service..."
systemctl restart mongod &>>$log_files
validate $? "Restarting MongoDB"

# Final message
echo -e "${m}MongoDB ${g}installation and setup completed successfully!${s}"

