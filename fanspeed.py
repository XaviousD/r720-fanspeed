#python3

#Python eqivalent of the fanspeed.sh script


import subprocess
import logging

FAN_SPEED_MIN = 0x00
FAN_SPEED_MAX = 0x64

ENABLE="raw 0x30 0x30 0x01 0x00"    # Hex Code for Enabling IPMI to control Fan Speeds
DISABLE="raw 0x30 0x30 0x01 0x01"   # Hex Code for giving control back to iDRAC
FAN="raw 0x30 0x30 0x02 0xff"       # Hex Code for adjusting fan speed last entry is fanspeed from above


##################################
# Soft Variables - Modify to User Preferences
###################################
#
# User/Password/Ip/Base Temps Etc
#
USERNAME="root"           # Login for iDRAC  - I suggest creating a specific account that only has access to fan control such as fanspeed
PASSWORD="calvin"         # Password for above login
HOSTIP="192.168.0.26"   # IP Address for the iDRAC interface on the system,
LAMBIENT="20"           # Ambient Inlet Air Temp for Silent Running Fan Curve [Less then or Equal to?]
NAMBIENT="21"           # Ambient Inlet Air Temp for Normal Running Fan Curve [Equal to or Greater then?]
HAMBIENT="24"           # Ambient Inlet Air Temp for Hot Running Fan Curve [Equal to or Greater then?]


if __name__ == "__main__":

    #check if ipmitool and jq is installed
    try:
        required_binaries=["ipmitool","jq","sensors"]
        for required in required_binaries:
            subprocess.check_output(f"which {required}", shell=True)
        
    except subprocess.CalledProcessError:
        
        logging.error("Install missing tools")
        logging.error("sudo apt install ipmitool jq lm-sensors")
        exit(1)


    #Let's assme for now the logic to get CPU temps is valid
    T1_command="$(sensors -Aj coretemp-isa-0000 | -jq '.[][] | to_entries[] | select(.key | endswith(\"input\")) | .value' | sort -rn | head -n1)"
    T2_command="$(sensors -Aj coretemp-isa-0001 | -jq '.[][] | to_entries[] | select(.key | endswith(\"input\")) | .value' | sort -rn | head -n1)"

    #run subprocess commands to get temps
    temperature_1 = subprocess.check_output(T1_command, shell=True).decode('utf-8')
    temperature_2 = subprocess.check_output(T2_command, shell=True).decode('utf-8')

    logging.info("CPU1 Temp: " + temperature_1)
    logging.info("CPU2 Temp: " + temperature_2)
    average_temp = (int(temperature_1) + int(temperature_2)) / 2
    logging.info("Average Temp: " + str(average_temp))

    #command to get ambient temp
    AMBIENT_command=f"ipmitool -I lanplus -H {HOSTIP} -U {USERNAME} -P {PASSWORD} sdr type temperature | grep -i inlet | grep -Po '\d{2,3} degrees C' | grep -Po '\d{2,3}')"
    ambient_temp = subprocess.check_output(AMBIENT_command, shell=True).decode('utf-8')
    logging.info("Ambient Temp: " + ambient_temp)

    SETFANSPEED_command= f"ipmitool -I lanplus -H {HOSTIP} -U {USERNAME} -P {PASSWORD} {FAN} "

    #testing if user can control fan speed
    #read value from input between 10 and 100

    #lets make 10 tests
    for i in range(10):
        fan_speed = input("Enter Fan Speed (10-100): ")
        fan_speed = int(fan_speed)
        if fan_speed < 10 or fan_speed > 100:
            print("Invalid Fan Speed")
            exit()
        else:
            logging.info("Trying to set fan speed to: " + str(fan_speed))
            #convert int to hex representation 0x%d%d
            fan_speed_hex = hex(fan_speed)
            SETFANSPEED_command_full = SETFANSPEED_command + fan_speed_hex
            logging.info("Command: " + SETFANSPEED_command_full)
            subprocess.call(SETFANSPEED_command_full, shell=True)
            logging.info("Fan Speed Set, did it work?")

