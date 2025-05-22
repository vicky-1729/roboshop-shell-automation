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

# Disable default Nginx module
echo -e "${y}Disabling Nginx module...${s}"

dnf module disable nginx -y &>> "$LOG_FILES"
validate $? "Nginx disabling"

# Enable Nginx 1.24 module
echo -e "${y}Enabling Nginx:1.24 module...${s}"

dnf module enable nginx:1.24 -y &>> "$LOG_FILES"
validate $? "Nginx:1.24 enabling"

# Install Nginx
echo -e "${y}Installing Nginx...${s}"

dnf install nginx -y &>> "$LOG_FILES"
validate $? "Nginx installation"

# Enable and start Nginx service
echo -e "${y}Starting the Nginx service...${s}"

systemctl enable nginx &>> "$LOG_FILES"
validate $? "Nginx service enable"

systemctl start nginx &>> "$LOG_FILES"
validate $? "Nginx service start"

# Remove the default content
echo -e "${y}Removing default content...${s}"

rm -rf /usr/share/nginx/html/* &>> "$LOG_FILES"
validate $? "Default content removal"

# Downloading the frontend
echo -e "${y}Downloading the frontend zip file...${s}"

curl -L -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> "$LOG_FILES"
validate $? "Frontend zip file downloading"

# Change to /usr/share/nginx/html directory
cd /usr/share/nginx/html

# Unzip the downloaded zip file
echo -e "${y}Unzipping the frontend zip file...${s}"

unzip /tmp/frontend.zip &>> "$LOG_FILES"
validate $? "Frontend zip file unzip"

# Copy custom Nginx configuration file
echo -e "${y}Copying custom Nginx configuration file...${s}"

cp $script_dir/repo/nginx.conf /etc/nginx/nginx.conf &>> "$LOG_FILES"
validate $? "Custom Nginx configuration file copy"

# Restart Nginx service
echo -e "${y}Restarting the Nginx service...${s}"

systemctl restart nginx &>> "$LOG_FILES"
validate $? "Nginx service restart"

# Final message
echo -e "${m}Nginx setup completed successfully..!${s}"
