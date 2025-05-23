#!/bin/bash



# Color codes
set -e

r="\033[31m"   # Red
g="\033[32m"   # Green
y="\033[33m"   # Yellow
b="\033[34m"   # Blue
m="\033[35m"   # Magenta
reset="\033[0m"  # Reset

#creating the folder for logs
LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOGS_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
S_DIR=$(PWD)

mkdir -p $LOG_FOLDER 

# Check if the script is being run as the root user
if [ "$(id -u)" -eq 0 ];
then
    echo -e "${g}✔ Running as root user.${reset}" | tee -a "$LOG_FILE"
else
    echo -e "${r}✖ Error:${reset} This script must be run as root. Please use sudo or switch to the root user." | tee -a "$LOG_FILE"
    exit 1
fi


# Function to validate the exit status of commands and print appropriate messages
VALIDATE() {
    if [ "$1" -eq 0 ]; then
        echo -e "${g}✔ $2 succeeded.${reset}"
    else
        echo -e "${r}✖ $2 failed.${reset}"
        exit 1
    fi
}






