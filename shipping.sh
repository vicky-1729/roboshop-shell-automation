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

# Variables
USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo "$0" | cut -d '.' -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
S_DIR=$PWD

# Create log directory
mkdir -p "$LOGS_FOLDER"

# Root privilege check
if [ "$USERID" -ne 0 ]; then
    echo -e "${r}ERROR:: Please run this script with root access${reset}" | tee -a "$LOG_FILE"
    exit 1
fi

# Validation function
VALIDATE() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 ... ${g}SUCCESS${reset}" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... ${r}FAILURE${reset}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

#maven installation
dnf install maven -y &>> "$LOG_FILE"
VALIDATE $? "installation of maven"

# roboshop user setup
if id roboshop &>/dev/null; then
    echo -e "roboshop user is ${g}already created${y} ... skipping${reset}" | tee -a "$LOG_FILE"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOG_FILE"
    VALIDATE $? "Creating roboshop system user"
fi

# Application setup
mkdir -p /app &>> "$LOG_FILE" &>> "$LOG_FILE"
VALIDATE $? "Creating /app directory"

rm -rf /app/* &>> "$LOG_FILE"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading shipping.zip"

cd /app
unzip /tmp/shipping.zip &>> "$LOG_FILE"
VALIDATE $? "Unzipping shipping.zip"

mvn clean package &>> "$LOG_FILE"
VALIDATE $? "mvn package cleaning"

mv target/shipping-1.0.jar shipping.jar  &>> "$LOG_FILE"
VALIDATE $? "moving of shipping of jar"

cp $S_DIR/service/shipping.service /etc/systemd/system/shipping.service &>> "$LOG_FILE"

systemctl daemon-reload
VALIDATE $? "system reloaded"

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "shipping service start "


dnf install mysql -y &>> "$LOG_FILE"
VALIDATE $? "installing mysql "
# Check if the 'cities' database exists and load data if not
# mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -e "SHOW DATABASES LIKE 'cities';" &>>$LOG_FILE
# if [ $? -ne 0 ]; then
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -e 'CREATE DATABASE IF NOT EXISTS cities;' &>> "$LOG_FILE"
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/schema.sql &>> "$LOG_FILE"
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/app-user.sql &>> "$LOG_FILE"
#     mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/master-data.sql &>> "$LOG_FILE"
#     VALIDATE $? "Loading database data"
# else
#     echo -e "Database data is ${y}already loaded${reset}, skipping..." | tee -a "$LOG_FILE"
# fi


# Check if the 'cities' database exists and load data if not
# Check if the 'cities' database exists and load data if not
DB_EXISTS=$(mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -sse "SHOW DATABASES LIKE 'cities';")
if [ "$DB_EXISTS" != "cities" ]; then
    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 -e 'CREATE DATABASE cities;' &>> "$LOG_FILE"
    VALIDATE $? "Creating cities database"

    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/schema.sql &>> "$LOG_FILE"
    VALIDATE $? "Loading schema.sql"

    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/app-user.sql &>> "$LOG_FILE"
    VALIDATE $? "Loading app-user.sql"

    mysql -h mysql.tcloudguru.in -u root -pRoboShop@1 cities < /app/db/master-data.sql &>> "$LOG_FILE"
    VALIDATE $? "Loading master-data.sql"
else
    echo -e "Database data is ${y}already loaded${reset}, skipping..." | tee -a "$LOG_FILE"
fi




systemctl restart shipping
VALIDATE $? "restarting shipping service"
