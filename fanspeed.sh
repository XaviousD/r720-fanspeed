#!/bin/bash
# Adapted from https://github.com/That-Guy-Jack/HP-ILO-Fan-Control/
# for Dell IPMI systems
# by https://jcx.life
# these original instructions might not be valid for installing it on your system.

# crontab -l > mycron
# echo "#" >> mycron
# echo "# At every 2nd minute" >> mycron
# echo "*/1 * * * * /bin/bash /autofan.sh >> /tmp/cron.log" >> mycron
# crontab mycron
# rm mycron
# chmod +x /autofan.sh
#

# Variables That Can Be Changed

USERNAME=root
PASSWORD=calvin
HOSTIP="192.168.0.26"
MINTEMP="50"
TEMP1="52"
TEMP2="54"
TEMP3="58"
MAXTEMP="67"
FANSPEED10="0x0a"
FANSPEED20="0x14"
FANSPEED30="0x1e"
FANSPEED40="0x28"
FANSPEED50="0x32"
FANSPEED60="0x3c"
FANSPEED70="0x46"
FANSPEED80="0x50"
FANSPEED90="0x5a"
FANSPEEDMAX="0x64"

COMMAND="raw 0x30 0x30 0x02 0xff"

T1="$(sensors -Aj coretemp-isa-0000 | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort -rn | head -n1)"
T2="$(sensors -Aj coretemp-isa-0001 | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort -rn | head -n1)"
TOTALTEMP=$(($T1+$T2))
AVGTEMP=$(($TOTALTEMP/2))

echo "==============="
echo "CPU 1: $T1 - CPU 2: $T2 - Average: $AVGTEMP"
echo "==============="

if [[ $AVGTEMP > $MAXTEMP ]]
   then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $COMMAND $FANSPEEDMAX
elif [[ $AVGTEMP > $TEMP3 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $COMMAND $FANSPEED80

elif [[ $AVGTEMP > $TEMP2 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $COMMAND $FANSPEED60
elif [[ $AVGTEMP > $TEMP1 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $COMMAND $FANSPEED40
elif [[ $AVGTEMP > $MINTEMP ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $COMMAND $FANSPEED30
else
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $COMMAND $FANSPEED20
fi
