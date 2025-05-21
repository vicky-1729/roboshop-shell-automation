#!/bin/bash

# color codes
# Define colors
r="\e[31m"
g="\e[32m"
y="\e[33m"
m="\e[36m"
s="\e[0m"

# Check whether the user is root or not

if [ "$(id -u)" -eq 0 ]
then
    echo -e "your are a ${r} root ${s} user you directly run the script"
else
    echo -e  "you are ${r} not a root user ${s} please run the script with sudo"
    exit 1
fi


validate (){
    if [ "$1" -eq 0 ]
    then
       echo -e "$2 is ${g} success..! ${s}"
    else
       echo -e "$2 is ${r} failed..! ${s}"
       exit 1
    fi
}

cp repos/mongo.repo /etc/yum.repos.d/mongodb.repo
validate $? "creating repo file"

dnf install mongodb-org -y 
validate $? "installing mongodb"

systemctl enable mongod 
validate $? "enabling mongodb"

systemctl start mongod 
validate $? "starting mongodb"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
validate $? "updating mongodb config file changed 0.0.0.0 to open for all ip"

systemctl restart mongod 
validate $? "restarting mongodb"







