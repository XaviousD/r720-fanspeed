# Adapted from https://github.com/That-Guy-Jack/HP-ILO-Fan-Control/
# for Dell IPMI systems by https://jcx.life
#
# these original instructions might not be valid for installing it on your system.
#
# Contributers via Discord
# ------------------------
# Cichy / Blade
# 
#
# FOR LATER USE/TWEEKING 
#
# !/bin/bash
# crontab -l > mycron THIS ONE LIST ALL CRONS AND SAVES IT TO FILE
# echo "#" >> mycron THIS ADDS COMMENT START TO SAVED CRONS 
# echo "# At every 2nd minute" >> mycron THIS IS COMMENT SO OTHER KNOW HOW OFTEN IT WILL RUN
# echo "*/1 * * * * /bin/bash /fanspeed.sh >> /tmp/cron.log" >> mycron THIS LINE ADD CRON JOB, RUNNING FANSPEED.SH EVERY X MINUTES AND REDIRECT OUTPUT TO LOG IN TMP
# crontab mycron THIS ONE TO LOAD CRONS FRON FILE
# rm mycron
# chmod +x /fanspeed.sh THIS ONE MAKES SCRIPT ECECUTABLE
#
# ty Cichy from TechnoTim's discord for helping me understand crontab formatting
#
## Notes from Xavious
# THIS IS VERY EARLY WORK
# This is not ready for production. Download/hackup as your own risk.
# This above lines will be removed when the code is actually usable.
#
##################################
# PreReq's that need to be installed
##################################
#  
# ipmitool
# lm-sensors
#
##################################
# Hard Variables - Do not Change #
##################################
#
# Fan Speed Hex Codes
# AVG RPM Obtained by setting fan % and taking an average of the RPM on the 7 fans in r720's
#
FS10="0x0a"         # Hex Code for 10% RPM or AVG 2360 RPM      
FS20="0x14"         # Hex Code for 20% RPM or AVG 3340 RPM
FS30="0x1e"         # Hex Code for 30% RPM or AVG 4880 RPM
FS40="0x28"         # Hex Code for 40% RPM or AVG 6200 RPM
FS50="0x32"         # Hex Code for 50% RPM or AVG 7280 RPM
FS60="0x3c"         # Hex Code for 60% RPM or AVG 8640 RPM
FS70="0x46"         # Hex Code for 70% RPM or AVG 9680 RPM
FS80="0x50"         # Hex Code for 80% RPM or AVG 10640 RPM
FS90="0x5a"         # Hex Code for 90% RPM or AVG 11820 RPM
FSMAX="0x64"        # Hex Code for 100% RPM or AVG 12660 RPM
#
#
# Enable/Disable User Controlled Fan Speeds 
ENABLE="raw 0x30 0x30 0x01 0x00"    # Hex Code for Enabling IPMI to control Fan Speeds
DISABLE="raw 0x30 0x30 0x01 0x01"   # Hex Code for giving control back to iDRAC
FAN="raw 0x30 0x30 0x02 0xff"       # Hex Code for adjusting fan speed last entry is fanspeed from above
#
##################################
# Soft Variables - Modify to User Preferences
###################################
#
# User/Password/Ip/Base Temps Etc
#
USERNAME=root           # Login for iDRAC  - I suggest creating a specific account that only has access to fan control such as fanspeed
PASSWORD=calvin         # Password for above login
HOSTIP="192.168.0.26"   # IP Address for the iDRAC interface on the system,
LAMBIENT="20"           # Ambient Inlet Air Temp for Silent Running Fan Curve [Less then or Equal to?]
NAMBIENT="20"           # Ambient Inlet Air Temp for Normal Running Fan Curve [Equal to or Greater then?]
HAMBIENT="24"           # Ambient Inlet Air Temp for Hot Running Fan Curve [Equal to or Greater then?]
LMINTEMP="??"            # Temp that determines if system is idle and sets fan speeds to 10%
LMAXTEMP="??"            # Temp that determines if system is overheating and max fanspeeds are used.   
LMINTEMP="??"            # Temp that determines if system is idle and sets fan speeds to 10%
LMAXTEMP="??"            # Temp that determines if system is overheating and max fanspeeds are used.   
LMINTEMP="??"            # Temp that determines if system is idle and sets fan speeds to 10%
LMAXTEMP="??"            # Temp that determines if system is overheating and max fanspeeds are used.   
#
# Silent Running Fan Curve Temps
# These have a great Gap between the curves, fewer steps, and high degree of change before next step is set
#
LFC01="??"               # 30% RPM
LFC02="??"               # 50% RPM
LFC03="??"               # 70% ROM
#
# Normal Running Fan Curve Temps
# These have a great Gap between the curves, fewer steps, and high degree of change before next step is set
#
NFC01="??"               #
NFC02="??"               #
NFC03="??"               #
NFC04="??"               #
NFC05="??"               #
NFC06="??"               #
NFC07="??"               #
NFC08="??"               #
NFC09="??"               #
NFC10="??"               #
#
# Hot Running Fan Curve Temps
# These have a great Gap between the curves, fewer steps, and high degree of change before next step is set
#
HFC01="??"               #
HFC02="??"               #
HFC03="??"               #
HFC04="??"               #
HFC05="??"               #
#
#
## To-Do
## Ideas
##
## Setup Ambient temp variables.  Have system check the ambient temp value and adjust fan curve accordingly.
## Example = If ambient is < LAMBIENT then fan curve speeds and reduced by 10% each step.
#
#           With a Normal Ambient operation speeds may be 10% 20% 30% 40% 50% 60% 70% 80% 90% MAX in the curve
#
#           In Low Ambient operations speeds would be 10% 30% 50% 70% MAX
#
#           In a High Ambient operations would use same curve as Normal but with
#           a faster change with fewer degrees of change allowed between speed changes
#
#

T1="$(sensors -Aj coretemp-isa-0000 | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort -rn | head -n1)"
T2="$(sensors -Aj coretemp-isa-0001 | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort -rn | head -n1)"
TOTALTEMP=$(($T1+$T2))
AVGTEMP=$(($TOTALTEMP/2))

echo "==============="
echo "CPU 1: $T1 - CPU 2: $T2 - Average: $AVGTEMP"
echo "==============="

#
# Silent Running Fan Curve
#

if [[ $AVGTEMP > $MAXTEMP ]]
   then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FSMAX
elif [[ $AVGTEMP > $LFC03 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED80

elif [[ $AVGTEMP > $LFC02 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED60
elif [[ $AVGTEMP > $LFC01 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED40
elif [[ $AVGTEMP > $MINTEMP ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED30
else
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED20
fi

#
# Normal Running Fan Curve
#

if [[ $AVGTEMP > $MAXTEMP ]]
   then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FSMAX
elif [[ $AVGTEMP > $TEMP3 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED80

elif [[ $AVGTEMP > $TEMP2 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED60
elif [[ $AVGTEMP > $TEMP1 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED40
elif [[ $AVGTEMP > $MINTEMP ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED30
else
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED20
fi

#
# Hot Running Fan Curve
#

if [[ $AVGTEMP > $MAXTEMP ]]
   then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FSMAX
elif [[ $AVGTEMP > $TEMP3 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED80

elif [[ $AVGTEMP > $TEMP2 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED60
elif [[ $AVGTEMP > $TEMP1 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED40
elif [[ $AVGTEMP > $MINTEMP ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED30
else
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FANSPEED20
fi
