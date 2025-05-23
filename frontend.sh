#!/bin/bash

# Color codes
R="\e[31m"   # Red
G="\e[32m"   # Green
Y="\e[33m"   # Yellow
C="\e[36m"   # Cyan
N="\e[0m"    # Reset

# Root privilege check
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${R}ERROR: Please run this script with root access${N}"
    exit 1
else
    echo -e "${C}You are running with root access${N}"
fi

# Log setup
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p "$LOG_FOLDER"
echo "Script started at: $(date)" | tee -a "$LOG_FILE"

# Validation function
validate() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 ... ${G}SUCCESS${N}" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... ${R}FAILURE${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Check required tools
for cmd in curl unzip nginx; do
    command -v $cmd &>/dev/null || { echo -e "${R}$cmd not found. Please install it.${N}"; exit 1; }
done

# Nginx setup
dnf module disable nginx -y &>>"$LOG_FILE"
validate $? "Disabling default Nginx module"

dnf module enable nginx:1.24 -y &>>"$LOG_FILE"
validate $? "Enabling Nginx:1.24 module"

dnf install nginx -y &>>"$LOG_FILE"
validate $? "Installing Nginx"

systemctl enable nginx &>>"$LOG_FILE"
systemctl start nginx &>>"$LOG_FILE"
validate $? "Starting Nginx service"

# Clean default content
rm -rf /usr/share/nginx/html/* &>>"$LOG_FILE"
validate $? "Removing default Nginx content"

# Download frontend
curl -L -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>"$LOG_FILE"
validate $? "Downloading frontend"

cd /usr/share/nginx/html || exit
unzip /tmp/frontend.zip &>>"$LOG_FILE"
validate $? "Unzipping frontend"

# Replace nginx.conf
if [ ! -f "$SCRIPT_DIR/repos/nginx.conf" ]; then
    echo -e "${R}Custom nginx.conf not found at $SCRIPT_DIR/repos/nginx.conf${N}" | tee -a "$LOG_FILE"
    exit 1
fi

cp "$SCRIPT_DIR/repos/nginx.conf" /etc/nginx/nginx.conf &>>"$LOG_FILE"
validate $? "Copying custom nginx.conf"

# Validate nginx config before restart
nginx -t &>>"$LOG_FILE"
validate $? "Validating Nginx configuration"

systemctl restart nginx &>>"$LOG_FILE"
validate $? "Restarting Nginx"

echo -e "${C}Nginx setup completed successfully!${N}"
