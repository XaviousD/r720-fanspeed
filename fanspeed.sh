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
# jq
#
##################################
# Hard Variables - Do not Change #
##################################
#
# Default Ambient Temp, start at 0, script gets current ambient temp for curve checks
#
AMBIENT="0"     # Base Ambient just for listing the variable in the script so i know its in use.
C_FS="Unknown"  # Current FanSpeed %, Script sets this for information purposes later.
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
# USERNAME=root           # Login for iDRAC  - I suggest creating a specific account that only has access to fan control such as fanspeed
# PASSWORD=calvin         # Password for above login
# HOSTIP="192.168.0.26"   # IP Address for the iDRAC interface on the system,
LAMBIENT="20"           # Ambient Inlet Air Temp for Silent Running Fan Curve [Less then or Equal to?]
NAMBIENT="21"           # Ambient Inlet Air Temp for Normal Running Fan Curve [Equal to or Greater then?]
HAMBIENT="24"           # Ambient Inlet Air Temp for Hot Running Fan Curve [Equal to or Greater then?]

LMINTEMP="??"            # Temp that determines if system is idle and sets fan speeds to 10%
LMAXTEMP="??"            # Temp that determines if system is overheating and max fanspeeds are used.   
LMINTEMP="??"            # Temp that determines if system is idle and sets fan speeds to 10%
LMAXTEMP="??"            # Temp that determines if system is overheating and max fanspeeds are used.   
LMINTEMP="??"            # Temp that determines if system is idle and sets fan speeds to 10%
LMAXTEMP="??"            # Temp that determines if system is overheating and max fanspeeds are used.   
#
# Silent Running Fan Curve Temps
# These should have your larger degree change between the levels for a silent fan curve when server is idle and low ambient temps
#
LFC01="??"               # 30% RPM
LFC02="??"               # 50% RPM
LFC03="??"               # 70% RPM
#
# Normal Running Fan Curve Temps
# These should have your nominal degree change between the levels for a normal fan curve with standard ambient temps
#
NFC01="??"               # 30% RPM
NFC02="??"               # 40% RPM
NFC03="??"               # 50% RPM
NFC04="??"               # 60% RPM
NFC05="??"               # 70% RPM
NFC06="??"               # 80% RPM
NFC07="??"               # 90% RPM
#
# Hot Running Fan Curve Temps
# These should have your smaller degree change between the levels for a fan curve when server is under load and high ambient temps
# These have a smallgreat Gap between the curves, fewer steps, and high degree of change before next step is set
#
HFC01="??"               # 30% RPM
HFC02="??"               # 40% RPM
HFC03="??"               # 50% RPM
HFC04="??"               # 60% RPM
HFC05="??"               # 70% RPM
#
#
## To-Do
## Ideas
##
## Setup Ambient temp variables.  Have system check the ambient temp value and adjust fan curve accordingly.
## Example = If ambient is < LAMBIENT then fan curve speeds and reduced by 10% each step.
#
#           In Low Ambient operations speeds would be 10% 30% 50% 70% MAX
#
#           With a Normal Ambient operation speeds may be 10% 20% 30% 40% 50% 60% 70% 80% 90% MAX in the curve
#
#           In a High Ambient operations would use same curve points as Low but closer fan curve
#           a faster change with fewer degrees of change allowed between speed changes
#
# Get the CPU Core temps for both CPU's, Average the temps for each CPU then Average those to get a system CPU temp to use for
# in fav curves
#
T1="$(sensors -Aj coretemp-isa-0000 | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort -rn | head -n1)"
T2="$(sensors -Aj coretemp-isa-0001 | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort -rn | head -n1)"
TOTALTEMP=$(($T1+$T2))
AVGTEMP=$(($TOTALTEMP/2))
#
# Get Current Ambient temp to determine which fan curve to use
#
AMBIENT=$(ipmitool sdr type temperature | grep -i inlet | grep -Po '\d{2,3} degrees C' | grep -Po '\d{2,3}')
#
# Print Current Temps
#
echo "=========================================================================================="
echo " CPU 1: $T1 - CPU 2: $T2 - Average: $AVGTEMP - Ambient: $AMBIENT - Fan Speed Hex: ???? - Fan Speed: ???"
echo "=========================================================================================="
#
# Start of all the Fan Curves
#
if [[ $AMBIENT > $HAMBIENT ]]
   then
        #The curves for High Ambient Curve
elif [[ $AMBIENT > $NAMBIENT ]]
    then
        #The curves for Normal Ambient Curve
elif [[ $AMBIENT < $LOWAMBIENT ]]
    then
        if [[ $AVGTEMP > $LMAXTEMP ]]
           then
                ipmitool $FAN $FSMAX
        elif [[ $AVGTEMP > $LFC03 ]]
            then
                ipmitool $FAN $FS70
        elif [[ $AVGTEMP > $LFC02 ]]
            then
                ipmitool $FAN $FS50
        elif [[ $AVGTEMP > $LFC01 ]]
            then
                ipmitool $FAN $FS30
        elif [[ $AVGTEMP > $MINTEMP ]]
            then
                ipmitool $FAN $FS20
        else
                ipmitool $FAN $FS10
        fi
fi


if [[ $AVGTEMP > $MAXTEMP ]]
   then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FSMAX
elif [[ $AVGTEMP > $LFC03 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS70
elif [[ $AVGTEMP > $LFC02 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS50
elif [[ $AVGTEMP > $LFC01 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS30
elif [[ $AVGTEMP > $MINTEMP ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS20
else
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS10
fi

#
# Normal Running Fan Curve
#

if [[ $AVGTEMP > $MAXTEMP ]]
   then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FSMAX
elif [[ $AVGTEMP > $NFC07 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS90
elif [[ $AVGTEMP > $NFC06 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS80
elif [[ $AVGTEMP > $NFC05 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS70
elif [[ $AVGTEMP > $NFC04 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS60
elif [[ $AVGTEMP > $NFC03 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS50
elif [[ $AVGTEMP > $NFC02 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS40
elif [[ $AVGTEMP > $NFC01 ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS30
elif [[ $AVGTEMP > $MINTEMP ]]
    then
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS20
else
        ipmitool -I lanplus -H $HOSTIP -U $USERNAME -P $PASSWORD $FAN $FS10
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
