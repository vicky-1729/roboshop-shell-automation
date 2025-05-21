#!/bin/bash
# Color codes
r="\e[31m"   # Red
g="\e[32m"   # Green
y="\e[33m"   # Yellow
m="\e[36m"   # Cyan 
s="\e[0m"    # Reset

# Check whether the user is root or not
id -u
if [ $? -eq 0 ]
then
    echo -e "your are root user"
else
    echo -r "your are not root user please sudo user"
    exit 1
fi

