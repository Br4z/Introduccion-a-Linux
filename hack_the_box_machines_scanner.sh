#!/bin/bash


green_color="\e[0;32m"
red_color="\e[0;31m"
blue_color="\e[0;34m"
yellow_color="\e[0;33m"
purple_color="\e[0;35m"
cyan_color="\e[0;36m"
gray_color="\e[0;37m"
end_color="\e[0m"


# Description: handle the Ctrl+C signal and exit the program.
# Parameters: none
function ctrl_c() {
	echo -e "${red_color}[-]${end_color}Exiting...\n"
	tput cnorm
	exit 1
}

trap ctrl_c INT

# ---------------------------------------------------------------------------- #

declare -r URL=https://htbmachines.github.io/bundle.js
declare -r PROGRAM_PATH=$HOME/.HTB_machines

# Description: displays the help panel with usage instructions for the script.
# Parameters: none
function help_panel() {
	echo -e "${green_color}[+]${end_color} Usage:\n"

	echo -e "$\t${purple_color}-m${end_color} <machine name> search a machine by its name\n"
	echo -e "$\t${purple_color}-i${end_color} <machine ip> search a machine by its IP\n"
	echo -e "$\t${purple_color}-y${end_color} <machine name> get the YouTube video URL of the machine\n"
	echo -e "$\t${purple_color}-d${end_color} <difficulty> get all the machines with the specified difficulty\n"
	echo -e "$\t${purple_color}-o${end_color} <machine OS> get all the machines with the specified OS\n"
	echo -e "$\t${purple_color}-s${end_color} <machine OS> get all the machines with the specified skill\n"
	echo -e "$\t${purple_color}-u${end_color} sync the database file\n"
	echo -e "$\t${purple_color}-h${end_color} display this panel\n"
}

# Description: checks if the program directory exists. If not, creates it.
# Parameters: None
function check_program_directory() {
	if [ ! -d "$PROGRAM_PATH" ]; then
		mkdir "$PROGRAM_PATH"
	fi
}

# Description:
# 	This function updates the database used by the Hack The Box Machines Scanner script.
# 	It checks if the program directory exists, retrieves the latest database from a URL,
# 	beautifies the downloaded database file, and compares it with the existing database file.
# 	If updates are found, it replaces the existing database file with the downloaded one.
# Parameters: none
function update_database() {
	check_program_directory
	tput civis
	curl -s -X GET $URL > "$PROGRAM_PATH/downloaded_database.js"
	js-beautify < "$PROGRAM_PATH/downloaded_database.js" | grep -w -A 10 -E "lf =|lf.push" | sponge "$PROGRAM_PATH/downloaded_database.js"

	if [ ! -f "$PROGRAM_PATH/database.js" ]; then
		mv "$PROGRAM_PATH/downloaded_database.js" "$PROGRAM_PATH/database.js"
	else
		md5sum_original_file=$(md5sum "$PROGRAM_PATH/database.js" | awk '{print $1}')
		md5sum_new_file=$(md5sum "$PROGRAM_PATH/downloaded_database.js" | awk '{print $1}')

		if [ $md5sum_original_file == $md5sum_new_file ]; then
			echo -e "${green_color}[+]${end_color} Updates not found"
		else
			echo -e "${green_color}[+]${end_color} Updates found"
			cat "$PROGRAM_PATH/downloaded_database.js" > "$PROGRAM_PATH/database.js"
		fi

		rm "$PROGRAM_PATH/downloaded_database.js"
	fi
	tput cnorm
}

# Description:
# 	Reads the contents of the database file and stores it in the 'database' variable.
# 	If the database file does not exist, it displays an error message, creates the database file,
# 	updates it, and exits the script.
# Parameters: None
function read_database() {
	if [ -f "$PROGRAM_PATH/database.js" ]; then
		database=$(cat "$PROGRAM_PATH/database.js")
	else
		echo -e "${red_color}[-]${end_color} Error: $PROGRAM_PATH/database.js does not exist"
		echo -e "${green_color}[+]${end_color} Creating the database file..."
		update_database
		exit 1
	fi
}

# Description: get machine contents from a database based on a specific field and value.
# Parameters:
# 	$1: criteria: the field to search for.
# 	$2: value: the value to match in the specified field.
# Returns: None
function get_machines_content_by_field() {
	criteria=$1
	value=$2

	machine_contents=$(echo "$database" | grep -C 9 -E "$criteria: \".*$value.*\"")

	if [ "$machine_contents" ]; then
		database="$(echo "$machine_contents" | grep -vE "id:|sku:|resuelta:" | sed "s/^ *//" | tr -d ",")"
	else
		(
			echo -e "${red_color}[-]${end_color} Error: there is(are) no machine(s) with"
			echo -e "$\"${blue_color}$criteria${end_color}\" = \"${blue_color}$value${end_color}\""
		)
		exit 1
	fi
}

# Description: search for a machine by its name in the database.
# Parameters: None.
function search_machine_by_name() {
	get_machines_content_by_field "name" "$machine_name"

	echo "$database" | awk "/name: \"$machine_name\"/,/youtube:/"
}

# Description: search for a machine by its IP address.
# Parameters: None
function search_machine_by_ip() {
	get_machines_content_by_field "ip" "$machine_ip"
	machine_name=$(echo "$database" | grep "name" | tr -d "\n")

	echo -e "${green_color}[+]${end_color} Machine name: $machine_name\tMachine IP: $machine_ip"
}

# Description: get the YouTube URL of a machine's video solution.
# Parameters: None.
function get_youtube_url() {
	get_machines_content_by_field "name" "$machine_name"

	youtube_url=$(echo "$database" | grep "youtube" | tr -d "\n")

	echo -e "${green_color}[+]${end_color} The YouTube video solution of the machine ${blue_color}$machine_name${end_color} is ${blue_color}$youtube_url${end_color}"
}

# Description: search machines by difficulty.
# Parameters: none.
function search_machines_by_difficulty() {
	get_machines_content_by_field "dificultad" "$machine_difficulty"
}

# Description: search machines by operating system.
# Parameters: none.
search_machines_by_os() {
	get_machines_content_by_field "so" "$machine_os"
}

# Description: search machines by skill.
# Parameters: none.
search_machines_by_skill() {
	get_machines_content_by_field "skills" "$machine_skill"
}

# Description: display machine(s) information.
# Parameters: none.
function show_machines() {
	if [ -n "$machine_difficulty" ]; then
		machine_difficulty=${difficulties[$machine_difficulty]}
		difficulty_color=""

		case "$machine_difficulty" in
			"Easy")
				difficulty_color="${green_color}"
				;;
			"Medium")
				difficulty_color="${yellow_color}"
				;;
			"Hard")
				difficulty_color="${red_color}"
				;;
			"Insane")
				difficulty_color="${gray_color}"
				;;
		esac
		echo -e "\t${blue_color}Difficulty${end_color} = ${difficulty_color}$machine_difficulty${end_color}"
	fi

	if [ -n "$machine_os" ]; then
		os_color=""

		case "$machine_os" in
			"Linux")
				os_color="${green_color}"
				;;
			"Windows")
				os_color="${blue_color}"
				;;
		esac

		echo -e "\t${blue_color}OS${end_color} = ${os_color}$machine_os${end_color}"
	fi

	if [ -n "$machine_skill" ]; then
		echo -e "\t${blue_color}Skill${end_color} = ${blue_color}$machine_skill${end_color}"
	fi

	machines=$(echo "$database" | grep "name" | tr -d "\"" | awk 'NF{print $NF}')
	echo
	echo "$machines" | column
}

# ---------------------------------------------------------------------------- #

declare -g database
declare -i option=0
declare -r difficulties=([Easy]='Fácil' [Medium]='Media' [Hard]='Difícil' [Insane]='Insane')

while getopts "m:i:y:d:o:s:uh" arg; do
	case $arg in
		m) machine_name=$OPTARG; let option+=1;;
		i) machine_ip=$OPTARG; let option+=2;;
		y) machine_name=$OPTARG; let option+=4;;
		d) machine_difficulty=$OPTARG; let option+=8;;
		o) machine_os=$OPTARG; let option+=16;;
		s) machine_skill=$OPTARG; let option+=32;;
		u) let option+=64;;
		h) ;;
	esac
done

read_database

case $option in
	1) search_machine_by_name;;
	2) search_machine_by_ip;;
	4) get_youtube_url;;
	8) search_machines_by_difficulty; show_machines;;
	16) search_machines_by_os; show_machines;;
	24)
		search_machines_by_difficulty
		search_machines_by_os
		show_machines
		;;
	32) search_machines_by_skill; show_machines;;
	40)
		search_machines_by_difficulty
		search_machines_by_skill
		show_machines
		;;
	48)
		search_machines_by_os
		search_machines_by_skill
		show_machines
		;;
	56)
		search_machines_by_difficulty
		search_machines_by_os
		search_machines_by_skill
		show_machines
		;;
	64) update_database;;
	*) help_panel;;
esac
