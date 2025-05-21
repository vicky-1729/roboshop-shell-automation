#!/bin/bash

# Color codes
r="\e[31m"   # Red
g="\e[32m"   # Green
y="\e[33m"   # Yellow
m="\e[36m"   # Cyan 
s="\e[0m"    # Reset

# Check whether the user is root or not
if [ $(id -u) -eq 0 ]
then
    echo -e "you are a ${m} root user${s} your can directly run the script"
else
    echo -e "you are ${r} not root user ${s} ,so please run the script using sudo"
    exit 1
fi


# Log folder setup
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
LOG_FILES="$LOG_FOLDER/$SCRIPT_NAME"
script_dir=$PWD
#making dirctory
mkdir -p $LOG_FOLDER

validate() {
    if [ "$1" -eq 0 ]
    then
        echo "$2 is success ...!" | tee -a "$LOG_FILES"
    else
        echo "$2 is failure ...!" | tea -a "$LOG_FILES"
    fi
}

echo "disbaling nodejs...."
dnf module disable nodejs -y &>> "$LOG_FILES"
validate $? "nodjes is disabled"


echo "enabling the nodejs:20...."
dnf module enable nodejs:20 -y &>> "$LOG_FILES"
validate $? "nodejs:20 is enabling"

echo "installing nodejs....."
dnf install nodejs -y &>> "$LOG_FILES"
validate $? "nodejs installation"


#Add application User
echo "adding user for roboshop ..."
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "roboshop user creation"

rm -rf /app/*

mkdir -p /app 
validate $? "app folder creation"


rm -rf /app/*
echo "downloading the catalogue zip file ...."
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> "$LOG_FILES"
validate $? "downloading catalogue zip"

cd /app

echo "unzipping the catalogue zip file ...."
unzip /tmp/catalogue.zip &>> "$LOG_FILES"
validate $? "unzipping catalogue zip"


echo "install the dependices..."
npm install &>> "$LOG_FILES"
validate $? "install the dependices"

echo "creating service for catalogue"
cp $script_dir/services/catalogue.service /etc/systemd/system/catalogue.service  &>> "$LOG_FILES"
validate $? "service has been created for the catalogue"


systemctl daemon-reload
systemctl enable catalogue  
systemctl start catalogue
VALIDATE $? "Starting Catalogue"


echo "creating the repo for the of mongodb clinet software  "
cp $script_dir/repos/mongo.repo /etc/yum.repos.d/mongodb.repo &>> "$LOG_FILES"
validate $? "added mongodb repo"

echo "installling the mongo db..."
dnf install mongodb-mongosh -y &>> "$LOG_FILES"
validate $? "installion of mongodb"


STATUS=$(mongosh --host  mongodb.tcloudguru.in --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [  "$STATUS" -lt 0 ]
then
    echo "loading the data into mongodb ..."
    mongosh --host mongodb.tcloudguru.in </app/db/master-data.js &>> "$LOG_FILES"
    validate $? "loading the data"
else
    echo "echo -e "Data is already loaded ... $Y SKIPPING $s""

echo "checking whethaer that ctaalogeu is connecting to mongodb or not ..."
telnet mongodb.tcloudguru.in 27017 &>> "$LOG_FILES"
validate $? "connection "


