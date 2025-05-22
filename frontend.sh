#!/bin/bash

# Color codes
r="\e[31m"   # Red
g="\e[32m"   # Green
y="\e[33m"   # Yellow
m="\e[36m"   # Cyan 
s="\e[0m"    # Reset

#checking whether user is root user or not

if [ $(id -u) -eq 0 ]
then
    echo -e "you are a ${g} root user${s} you can run the script"
else
    echo -e "you are ${r}not a root user ${s} you can run the script using sudo or root privalages"

#log folder setup

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILES="$LOG_FOLDER/$SCRIPT_NAME.log"
script_dir=$PWD

# Making directory for logs
mkdir -p "$LOG_FOLDER"

#validating either script is running is success or failure

validate(){
    if [ "$1" -eq 0 ]
    then
        echo "$2 is ....success"
    else
        echo "$2 is ....failure"
    fi
}

dnf module disable nginx -y
validate $? "disbale nginx"

dnf module enable nginx:1.24 -y
validate $? "enable nginx"

dnf install nginx -y
validate $? "install nginx"

systemctl enable nginx
validate $? "system enable nginx"

systemctl start nginx
validate $? "system start nginx"

#remove the defualt content 

rm -rf /usr/share/nginx/html/* 

#downlodaing the frontend
curl -L -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "frontend zip file downloading"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip
validate $? "frontend zip file unzip"

cp $script_dir/repo/nginx.conf /etc/nginx/nginx.conf

systemctl restart nginx 
validate $? "system restart nginx"