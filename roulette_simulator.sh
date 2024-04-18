#!/bin/bash


green_color="\e[0;32m"
end_color="\e[0m"
red_color="\e[0;31m"
blue_color="\e[0;34m"
yellow_color="\e[0;33m"
purple_color="\e[0;35m"
cyan_color="\e[0;36m"
gray_color="\e[0;37m"


# Description: handle the Ctrl+C signal and exit the program.
# Parameters: none
function ctrl_c() {
	echo -e "${red_color}[-]${end_color}Exiting...\n"
	tput cnorm
	exit 1
}

trap ctrl_c INT

# ---------------------------------------------------------------------------- #

# Description: displays the usage instructions for the roulette simulator script.
# Parameters: none
function help_panel() {
	echo -e "${green_color}[+]${end_color} Usage:\n"

	echo -e "$\t${purple_color}-m${end_color} <amount of money> specify the amount of money you want to bet\n"
	echo -e "$\t${purple_color}-t${end_color} <betting technique> specify the betting technique you want to use in your bet\n"
	echo -e "$\t\t${purple_color}1)${end_color} Martingala \t ${purple_color}2)${end_color} Inverse Labouchere\n"
	echo -e "$\t${purple_color}-h${end_color} display this panel\n"
}

# Description: validates the amount of money entered by the user.
# Parameters: none
function validate_money() {
	if [[ ! $money =~ ^[0-9]+$ ]]; then
		echo -e "${red_color}[-]${end_color} Error: invalid amount of money"
		exit 1
	fi
}

# Description:
# 	Simulates a roulette game using the Martingale betting strategy.
# 	It prompts the user to enter the initial bet amount and the betting mode (0 for Even or 1 for Odd).
# 	The function then starts a loop where it generates a random number between 0 and 36 (representing the roulette wheel).
# 	If the number is even and the betting mode is 0, or if the number is odd and the betting mode is 1, the player wins and the bet amount is added to their money.
# 	If the number does not match the betting mode, the player loses and the bet amount is doubled for the next round.
# 	The function keeps track of the player's money, the number of plays, the longest losing streak, and the maximum money earned.
# 	The loop continues until the player runs out of money or decides to stop.
# Parameters: None
function martingala() {
	echo -e "Money: ${green_color}\$${end_color}$money"
	echo -ne "Write the amount for the initial beat: " && read -r initial_bet
	echo -ne "Write the beeting mode (0 for Even or 1 for Odd): " && read -r beeting_mode

	bet=$initial_bet
	plays=0
	longest_losing_streak=""
	max_money=$money

	tput civis
	while true; do
		echo "# ---------------------------------------------------------------------------- #"
		number=$((RANDOM % 37))
		echo -e "Result: ${blue_color}$number${end_color}"

		if [ $money -gt 0 ] && [ $bet -le $money ]; then
			remainder=$((number % 2))

			if [ $remainder -eq 0 ]; then
				echo -n "The number is even."
			else
				echo -n "The number is odd."
			fi

			if [ $remainder -eq $beeting_mode ] && [ $number -ne 0 ]; then
				echo -e "You have ${green_color}win${end_color} ${green_color}\$${end_color}$bet"
				result=$bet
				bet=$initial_bet
				longest_losing_streak=""
			else
				echo -e "You have ${red_color}lost${end_color}"
				result=$((-1 * bet))
				bet=$((2 * bet))
				longest_losing_streak+="$number "
			fi

			money=$((money + result))

			if [ $money -gt $max_money ]; then
				max_money=$money
			fi

			(( plays++ )) || true

			echo -e "Money: ${green_color}\$${end_color}${blue_color}$money${end_color}"
			echo -e "Bet: ${green_color}\$${end_color}${blue_color}$bet${end_color}"
		else
			if [ $bet -gt $money ]; then
				echo -e "${red_color}[-]${end_color} Your next bet is greater than your real amount of money"
			else
				echo -e "${red_color}[-]${end_color} You have run out of money"
			fi
			echo -e "Total plays: $plays"
			echo -e "Maximum money earned: $max_money"
			echo -e "Longest losing streak: $longest_losing_streak"
			tput cnorm
			exit 0
		fi
	done
	tput cnorm
}

# Description:
# 	Simulates a roulette game using the inverse Labouchere betting system.
# 	The player starts with a sequence of numbers and places bets based on the sum of the first and last numbers in the sequence.
# 	If the bet is successful, the player adds the bet amount to the sequence.
# 	If the bet is unsuccessful, the player removes the first and last numbers from the sequence.
# 	The game continues until the player reaches the upper limit of their money or runs out of money.
# Parameters: none
function inverse_labouchere() {
	echo -e "Money: ${green_color}\$${end_color}$money"
	echo -ne "Write the beeting mode (0 for Even or 1 for Odd): " && read -r beeting_mode

	declare -a initial_sequence=(1 2 3 4 5)
	declare -a sequence=(${initial_sequence[@]})

	money_ceil=$(echo "$money * (1 + 0.25)" | bc -l | awk '{printf "%.0f", $0}')
	money_floor=$(echo "$money * (1 - 0.25)" | bc -l | awk '{printf "%.0f", $0}')
	plays=0
	longest_losing_streak=""
	max_money=$money

	while true; do
		echo "# ---------------------------------------------------------------------------- #"
		number=$((RANDOM % 37))
		echo -e "Result: ${blue_color}$number${end_color}"

		if [ $money -ge $money_ceil ]; then
			echo "The upper limit has been reached, restarting the sequence"
			sequence=(${initial_sequence[@]})
			((money_ceil+=$(echo "$money * (1 + 0.25)" | bc -l | awk '{printf "%.0f", $0}')))
		elif [ $money -le $money_floor ]; then
			echo "The lower limit has been reached, restarting the sequence"
			sequence=(${initial_sequence[@]})
			((money_floor-=$(echo "$money * (1 - 0.25)" | bc -l | awk '{printf "%.0f", $0}')))
		fi

		if [ ${#sequence[@]} -eq 0 ]; then
			sequence=(${initial_sequence[@]})
			bet=$((sequence[0] + sequence[-1]))

			unset "sequence[0]"
			unset "sequence[-1]"

			sequence=(${sequence[@]})
		elif [ ${#sequence[@]} -eq 1 ]; then
			bet=${sequence[0]}

			sequence=(${initial_sequence[@]})
		else
			bet=$((sequence[0] + sequence[-1]))

			unset "sequence[0]"
			unset "sequence[-1]"

			sequence=(${sequence[@]})
		fi

		if [ $money -gt 0 ] && [ $bet -le $money ]; then
			remainder=$((number % 2))

			if [ $remainder -eq 0 ]; then
				echo -n "The number is even."
			else
				echo -n "The number is odd."
			fi

			if [ $remainder -eq $beeting_mode ] && [ $number -ne 0 ]; then
				echo -e "You have ${green_color}win${end_color} ${green_color}\$${end_color}$bet"
				result=$bet
				sequence+=($bet)
				longest_losing_streak=""
			else
				echo -e "You have ${red_color}lost${end_color}"
				result=$((-1 * bet))
				longest_losing_streak+="$number "
			fi

			money=$((money + result))

			if [ $money -gt $max_money ]; then
				max_money=$money
			fi

			(( plays++ )) || true

			echo -e "Money: ${green_color}\$${end_color}${blue_color}$money${end_color}"
			echo -e "Bet: ${green_color}\$${end_color}${blue_color}$bet${end_color}"
			echo -e "Upper limit: ${green_color}\$${end_color}${blue_color}$money_ceil${end_color}"
			echo -e "Lower limit: ${green_color}\$${end_color}${blue_color}$money_floor${end_color}"
			echo -e "Sequence: [${sequence[*]}]"
		else
			if [ $bet -gt $money ]; then
				echo -e "${red_color}[-]${end_color} Your next bet is greater than your real amount of money"
			else
				echo -e "${red_color}[-]${end_color} You have run out of money"
			fi
			echo -e "Total plays: $plays"
			echo -e "Maximum money earned: $max_money"
			echo -e "Longest losing streak: $longest_losing_streak"
			tput cnorm
			exit 0
		fi
	done
}

# ---------------------------------------------------------------------------- #

while getopts "m:t:h" arg; do
	case $arg in
		m) money=$OPTARG;;
		t) technique=$OPTARG;;
		h) ;;
	esac
done

if [ $money ] && [ $technique ]; then
	validate_money
	case $technique in
		1)
			martingala;;
		2) inverse_labouchere;;
		*)
			echo -e "${red_color}[-]${end_color} Error: unkown technique"
			exit 1
			;;
	esac
else
	help_panel
	exit 1
fi
