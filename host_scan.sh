#!/bin/bash


# Description: handle the Ctrl+C signal and exit the program.
# Parameters: none
function ctrl_c() {
	echo -e "\nExiting...\n"
	exit 1
}

trap ctrl_c INT

ip="192.168.0"

for i in $(seq 1 254); do
	timeout 1 bash -c "ping -c 1 $ip.$i &>/dev/null" && echo "[+] $ip.$i" &
done; wait
