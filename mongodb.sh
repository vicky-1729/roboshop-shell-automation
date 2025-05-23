#!/bin/bash


# Color codes
set -e

r="\033[31m"   # Red
g="\033[32m"   # Green
y="\033[33m"   # Yellow
b="\033[34m"   # Blue
m="\033[35m"   # Magenta
reset="\033[0m"  # Reset


USERID=$(id -u)

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE


# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$r ERROR:: Please run this script with root access $reset" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo -e "You are running with $g root access $reset " | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $g SUCCESS $reset" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $r FAILURE $reset" | tee -a $LOG_FILE
        exit 1
    fi
}



cp $S_DIR/repo_config/mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
VALIDATE $? "Copying MongoDB repo file"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing mongodb server"


systemctl enable mongod
systemctl start mongod
VALIDATE $? "Starting mongodb server"

systemctl status mongod | grep Active &>> $LOG_FILE
VALIDATE $? "checking mongodb server is running"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>> $LOG_FILE

systemctl restart mongod
VALIDATE $? "restarting mongodb server"

