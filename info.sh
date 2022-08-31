# !/bin/bash
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
AMBIENT=$(ipmitool -I lanplus -H 192.168.0.26 -U root -P calvin sdr type temperature | grep -i inlet | grep -Po '\d{2,3} degrees C' | grep -Po '\d{2,3}')
#
# Print Current Temps
#
echo "==============="
echo "CPU 1: $T1 - CPU 2: $T2 - Average: $AVGTEMP - Ambient: $AMBIENT"
echo "==============="