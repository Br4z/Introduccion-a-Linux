#!/bin/bash


# Description: handle the Ctrl+C signal and exit the program.
# Parameters: none
function ctrl_c() {
	echo -e "\nExiting...\n"
	tput cnorm
	exit 1
}

trap ctrl_c INT

# Description: check the arguments passed to the script.
# Parameters:
# 	$1: start_port: the starting port number for the port scan.
# 	$2: end_port: the ending port number for the port scan.
function check_arguments() {
	if [[ $# -ne 2 ]]; then
		echo "Usage: $0 <start_port> <end_port>"
		exit 1
	fi
}

tput civis # Hide the cursor

check_arguments "$@"

start=$1
end=$2

for port in $(seq $start $end); do
	(echo "" > /dev/tcp/127.0.0.1/$port) 2>/dev/null && echo "[+] $port" &
done; wait

tput cnorm # Show the cursor
