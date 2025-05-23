#!/bin/bash
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

USERID=$(id -u)

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

# Set script directory
S_DIR=$(dirname "$0")


# Create log directory if it doesn't exist
mkdir -p $LOGS_FOLDER

# Check for root privileges
if [ $USERID -ne 0 ]; then
    echo -e "${r}ERROR:: Please run this script with root access${reset}" | tee -a $LOG_FILE
    exit 1
fi


# Validation function
VALIDATE() {
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... ${g}SUCCESS${reset}" | tee -a $LOG_FILE
    else
        echo -e "$2 ... ${r}FAILURE${reset}" | tee -a $LOG_FILE
        exit 1
    fi
}

# nodejs module installtion
dnf module disable nodejs -y
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling nodejs"

dnf install nodejs -y
VALIDATE $? "installing nodejs:20"

# creating the robo application
roboshop id
if [ "$?" -eq 0 ]
then
    echo -e "roboshop user  is $g  already created $y skipping $reset"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
fi

mkdir -p /app  &>> $LOG_FILE
VALIDATE $? "creating app folder" 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOG_FILE
VALIDATE $? "downloading the catalogue.zip file"

cd /app 
unzip /tmp/catalogue.zip &>> $LOG_FILE
VALIDATE $? "unzipping the catalogue file "

npm install &>> $LOG_FILE
VALIDATE $? "installing the dependices"

cp $S_DIR/service/catalogue.service /etc/systemd/system/catalogue.service &>> $LOG_FILE
VALIDATE $? "catalogue service creation"

systemctl daemon-reload
VALIDATE $? "system reloaded"

systemctl enable catalogue 
VALIDATE $? "enabling service"

systemctl start catalogue
VALIDATE $? "start service"

cp $S_DIR/repo_config/mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
VALIDATE $? "Copying MongoDB repo file"

dnf install mongodb-mongosh -y
VALIDATE $? "installing the mongodb client server"

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.tcloudguru.in </app/db/master-data.js &>> $LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $y SKIPPING $reset"
fi