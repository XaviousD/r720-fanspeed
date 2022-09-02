#python3

#Python eqivalent of the fanspeed.sh script


import subprocess
import logging
import time

FAN_SPEED_MIN = 0x00
FAN_SPEED_MAX = 0x64


##################################
# Soft Variables - Modify to User Preferences
###################################

LAMBIENT="20"           # Ambient Inlet Air Temp for Silent Running Fan Curve [Less then or Equal to?]
NAMBIENT="21"           # Ambient Inlet Air Temp for Normal Running Fan Curve [Equal to or Greater then?]
HAMBIENT="24"           # Ambient Inlet Air Temp for Hot Running Fan Curve [Equal to or Greater then?]

MINIMAL_FAN_SPEED=10
MAXIMAL_FAN_SPEED=100

MIN_TEMP = 26
MAX_TEMP = 58

SETFANSPEED_command_part1= "ipmitool raw 0x30 0x30 0x02 0xff "


def setFanSpeed(fan_speed):
    logging.info("Trying to set fan speed to: " + str(fan_speed))
    #convert int to hex representation 0x%d%d
    fan_speed_hex = "0x{:02x}".format(fan_speed)
    SETFANSPEED_command_full = SETFANSPEED_command_part1 + fan_speed_hex
    logging.info("Command: " + SETFANSPEED_command_full)
    subprocess.call(SETFANSPEED_command_full, shell=True)
    logging.info("Fan Speed Set, did it work?")

def translate(sensor_val, in_from, in_to, out_from, out_to):
    out_range = out_to - out_from
    in_range = in_to - in_from
    in_val = sensor_val - in_from
    val=(float(in_val)/in_range)*out_range
    out_val = out_from+val
    rounded = int(round(out_val, -1))
    return rounded

def get_CPU_temp():
    #Let's assme for now the logic to get CPU temps is valid
    T1_command="sensors -Aj coretemp-isa-0000 | jq '.[][] | to_entries[] | select(.key | endswith(\"input\")) | .value' | sort -rn | head -n1"
    T2_command="sensors -Aj coretemp-isa-0001 | jq '.[][] | to_entries[] | select(.key | endswith(\"input\")) | .value' | sort -rn | head -n1"

    #run subprocess commands to get temps
    temperature_1 = subprocess.check_output(T1_command, shell=True).decode('utf-8')
    temperature_2 = subprocess.check_output(T2_command, shell=True).decode('utf-8')

    logging.info("CPU1 Temp: " + temperature_1)
    logging.info("CPU2 Temp: " + temperature_2)
    average_temp = (int(temperature_1) + int(temperature_2)) / 2
    logging.info("Average Temp: " + str(average_temp))
    return average_temp

if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    '''
    #check if ipmitool and jq is installed
    try:
        required_binaries=["ipmitool","jq","sensors"]
        for required in required_binaries:
            subprocess.check_output(f"which {required}", shell=True)
        
    except subprocess.CalledProcessError:
        
        logging.error("Install missing tools")
        logging.error("sudo apt install ipmitool jq lm-sensors")
        exit(1)


    

    #command to get ambient temp
    AMBIENT_command="ipmitool sdr type temperature | grep -i inlet | grep -Po '\d{2,3} degrees C' | grep -Po '\d{2,3}'"
    ambient_temp = subprocess.check_output(AMBIENT_command, shell=True).decode('utf-8')
    logging.info("Ambient Temp: " + ambient_temp)

    '''

    user_input = 1
    while user_input != 0:
        print ("#############################################")
        print ("[1] Test setting fan speed")
        print ("[2] Simulate temperature change and see how fan reacts")
        print ("[3] Test script base don real temperature")
        print ("[0] Exit")
        print ("#############################################")

        
        while True:
            try:
                user_input = int(input("Enter your choice: "))
            except ValueError:
                print("Please enter a valid number")
                continue
            else:
                break

        if user_input == 1:
            
            try:
                fan_speed = input("Enter Fan Speed (10-100): ")
                fan_speed = int(fan_speed)
                if fan_speed < 10 or fan_speed > 100:
                    print("Please enter a valid fan speed")
                    continue
                setFanSpeed(fan_speed)

            except ValueError:
                logging.error("You entered not valid number")
                
        elif user_input == 2:
            logging.info("Simulating CPU Temperature Change")
            logging.info("Lets say for now ambient temp is irrelevant")
            logging.info("Lets say if temp of CPU is <= 30 then fanspeed will be 10%")
            logging.info("Lets say if temp of CPU is >= 80 fanspeed will be 100%")
            logging.info("Every value between (30-80) will be mapped to range of fan speed (10-100)")
            input_temp = 30
            while input_temp !=0 :
                input_temp = input("Enter CPU Temp (0 to exit): ")
                try:
                    input_temp = int(input_temp)
                    if input_temp == 0:
                        break
                    elif input_temp <= MIN_TEMP:
                        setFanSpeed(10)
                    elif input_temp >= MAX_TEMP:
                        setFanSpeed(100)
                    else:
                        #map input_temp to range of fan speed
                        #input_temp = 30-80
                        #fan_speed = 10-100
                        fan_speed = translate(input_temp, MIN_TEMP, MAX_TEMP, MINIMAL_FAN_SPEED, MAXIMAL_FAN_SPEED)
                        setFanSpeed(fan_speed)
                except ValueError:
                    logging.error("You entered not valid number")

        elif user_input == 3:
            while True:
                logging.info("Press Ctrl+C to exit")   
                input_temp = get_CPU_temp() 
                try:
                    input_temp = int(input_temp)
                    if input_temp == 0:
                        break
                    elif input_temp <= MIN_TEMP:
                        setFanSpeed(10)
                    elif input_temp >= MAX_TEMP:
                        setFanSpeed(100)
                    else:
                        #map input_temp to range of fan speed
                        #input_temp = 30-80
                        #fan_speed = 10-100
                        fan_speed = translate(input_temp, MIN_TEMP, MAX_TEMP, MINIMAL_FAN_SPEED, MAXIMAL_FAN_SPEED)
                        setFanSpeed(fan_speed)
                except ValueError:
                    logging.error("Wrong CPU temp readed")
                logging.info("Sleep for 60 seconds")
                time.sleep(60)
                


