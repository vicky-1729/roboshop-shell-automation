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
