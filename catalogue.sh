#!/bin/bash

# Color codes
r="\e[31m"   # Red
g="\e[32m"   # Green
y="\e[33m"   # Yellow
m="\e[36m"   # Cyan 
s="\e[0m"    # Reset

# Check whether the user is root or not
if [$(id -u) -eq 0 ]
then
    echo -e "you are a $(m)root user$(s) your can directly run the script"
else
    echo -e "you are $(r) not root user $(s) ,so please run the script using sudo"
    exit 1
fi


# Log folder setup
log_folder="/var/log/roboshop-logs"
script_name=$(echo $0 | cut -d '.' -f1)
log_files="$log_folder/$script_name"
script_dir=$PWD
#making dirctory
mkdir -p $log_folder

validate() {
    if [ "$1" -eq 0 ]
    then
        echo "$2 is success ...!" | tee -a "$log_files"
    else
        echo "$2 is failure ...!" | tea -a "$log_files"
}

echo "disbaling nodejs...."
dnf module disable nodejs -y
validate $? "nodjes is disabled"


echo "enabling the nodejs:20...."
dnf module enable nodejs:20 -y
validate $? "nodejs:20 is enabling"

echo "installing nodejs....."
dnf install nodejs -y
validate $? "nodejs installation"


#Add application User
echo "adding user for roboshop ..."
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "roboshop user creation"


mkdir /app 
validate $? "app folder creation"


echo "downloading the catalogue zip file ...."
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "downloading catalogue zip"

cd /app

echo "unzipping the catalogue zip file ...."
unzip /tmp/catalogue.zip
validate $? "unzipping catalogue zip"


echo "install the dependices..."
npm install 
validate $? "install the dependices"

echo "creating service for catalogue"
cp $script_dir/services/catalogue.service /etc/systemd/system/catalogue.service
validate $? "service has been created for the catalogue"


systemctl daemon-reload
systemctl enable catalogue  
systemctl start catalogue
VALIDATE $? "Starting Catalogue"


echo "creating the repo for the of mongodb clinet software  "
cp $script_dir/repos/mongo.repo /etc/yum.repos.d/mongodb.repo
validate $? "added mongodb repo"

echo "installling the mongo db..."
dnf install mongodb-mongosh -y
validate $? "installion of mongodb"

echo "loading the data into mongodb ..."
mongosh --host mongodb.tcloudguru.in </app/db/master-data.js
validate $? "loading the data"

echo "checking whetaher that mongodb is connected or not.."
mongosh --host mongodb.tcloudguru.in 
validate $? "connecting to mongodb "


