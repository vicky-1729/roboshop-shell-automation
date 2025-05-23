#!/bin/bash

# Color codes
R="\e[31m"   # Red
G="\e[32m"   # Green
Y="\e[33m"   # Yellow
C="\e[36m"   # Cyan
N="\e[0m"    # Reset

# Root privilege check
USERID=$(id -u)
if [ $USERID -ne 0 ]; then
    echo -e "${R}ERROR:: Please run this script with root access${N}"
    exit 1
else
    echo -e "${C}You are running with root access${N}"
fi

# Log setup
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
mkdir -p "$LOGS_FOLDER"
echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"

# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... ${G}SUCCESS${N}" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... ${R}FAILURE${N}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Nginx setup
dnf module disable nginx -y &>>"$LOG_FILE"
VALIDATE $? "Disabling default Nginx module"

dnf module enable nginx:1.24 -y &>>"$LOG_FILE"
VALIDATE $? "Enabling Nginx:1.24 module"

dnf install nginx -y &>>"$LOG_FILE"
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>"$LOG_FILE"
systemctl start nginx &>>"$LOG_FILE"
VALIDATE $? "Starting Nginx service"

rm -rf /usr/share/nginx/html/* &>>"$LOG_FILE"
VALIDATE $? "Removing default Nginx content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>"$LOG_FILE"
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html || exit
unzip /tmp/frontend.zip &>>"$LOG_FILE"
VALIDATE $? "Unzipping frontend"

rm -f /etc/nginx/nginx.conf &>>"$LOG_FILE"
VALIDATE $? "Removing default nginx.conf"

cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/nginx.conf &>>"$LOG_FILE"
VALIDATE $? "Copying custom nginx.conf"

systemctl restart nginx &>>"$LOG_FILE"
VALIDATE $? "Restarting Nginx"

echo -e "${C}Nginx setup completed successfully!${N}"
