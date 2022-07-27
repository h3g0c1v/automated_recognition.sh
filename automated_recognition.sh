#!/bin/bash

#Author: h3g0c1v
#The functionality of this script is to assist in the recognition of a machine when it is about to be compromised.
#./recognise.sh ip ...

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#Global Variables
number='^[0-9]+$'
ip=$1
checking_nmap=$(nmap -h &>/dev/null)
nmap_not_exist=$?
checking_whatweb=$(whatweb)
whatweb_not_exist=$?

# Ctrl + C
trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!] Coming out ...\n${endColour}"
	exit 1
}

#Function to help
function helpPanel(){
	echo -e "\n${redColour}[!] Usage: $0 IP${endColour}"
	for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\n\t${grayColour}[-h]${endColour}${yellowColour} Show this help Panel${endColour}"
	echo -e "\n\n${blueColour}(Example: $0 10.10.10.14)\n"
}

#Getting the operating system
function get_os(){
	ttl=$(sudo ping -c 1 $ip | grep "ttl" | awk 'NF{print$6}' | awk -F '=' 'NF{print$2}')

	if [ $ttl -ge "0" ] && [ $ttl -le "64" ]; then
		echo -e "\n${yellowColour}TTL($ttl) = Linux${endColour}\n"
	elif [ $ttl -ge "65" ] && [ $ttl -le "128" ]; then
		echo -e "\n${yellowColour}TTL($ttl) = Windows${endColour}\n"
	else
		echo -e "\n${yellowColour}TTL($ttl) = Unknown${endColour}\n"
	fi
}
#Options
function options(){
	echo -e "\n${blueColour}Choose an option${endColour}\n"
	echo -e "\t${blueColour}Do ping ${endColour}${yellowColour}                      [0]${endColour}"
	echo -e "\t${blueColour}Reconnaissance with nmap${endColour}${yellowColour}      [1]${endColour}"
	echo -e "\t${blueColour}Your victime has a web page${endColour}${yellowColour}   [2]${endColour}"
	echo -e "\t${blueColour}Simple fuzzing on a web page${endColour}${yellowColour}  [3]${endColour}"
	echo -e "\t${blueColour}Exit${endColour}${yellowColour}                          [4]${endColour}"
	echo -e "\n${blueColour}What do you want to do now?${endColour}${yellowColour}           [?]${endColour}\n"
	read value
}

#Ping function
function do_ping(){
	echo -e "\n${blueColour}[*] Sending an ICMP trace to IP: $ip${endColour}\n"
	sudo ping -c 1 $ip
}

#Reconnaissance with nmap
function first_nmap(){
	#Discovering open ports
	$(sudo nmap -p- --min-rate 5000 -vvv -n -Pn $ip -oG allPorts &>/dev/null)
}

#Getting the open ports to do second_nmap
function extractPorts () {
	ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')" 
	echo -e "${yellowColour}\t[*] Open ports: $ports\n${endColour}"
}

function second_nmap(){
	#Analysis of open ports
	sudo nmap -sCV -p$ports $ip -oN targeted
}

#Parameters
while getopts ":h" arg; do
	case $arg in
		h)
			helpPanel
			exit;;
	esac
done

#Checks
if [ "$*" == "" ]; then

	helpPanel
	exit

fi

if [ $nmap_not_exist != "0" ]; then

	echo -e "\n${redColour}To run this program is necessary have nmap tool, so I am going to install them${endColour}"
	apt install nmap

fi

if [ $whatweb_not_exist != "0" ]; then
	echo -e "\n${redColour}To run this program is necessary have whatweb tool, so I am going to install them${endColour}"
fi

#Root
if [ $(id -u) != 0 ]; then

	echo -e "\n${redColour}You need to be root${endColour}\n"
	exit 1

fi

if [ $(id -u) = 0 ]; then

	options

	while [ $value -gt 3 ] || [ $value -lt 0 ]; do
		echo -e "\n${redColour}Enter a number that is in the options${endColour}"
		options
	done

	while [ $value == "0" ] || [ $value == "1" ] || [ $value == "2" ] || [ $value == "3" ]; do

		if [ $value == "0" ]; then
			clear
			do_ping
			echo
			get_os
			options

		elif [ $value == "1" ]; then
			clear
			echo -e "\n${blueColour}[*] Discovering open ports${endColour}\n" 
			first_nmap
			extractPorts allPorts
			#Seeing which services are running on the open ports
			echo -e "${blueColour}[*] Seeing which services are running on the open ports${endColour}\n"
			second_nmap
			options

		elif [ $value == "2" ]; then
			clear
			echo -e "\n${blueColour}[*] Enter the URL of the web page (If it is a port other than 80 or 443 enter the corresponding port)${endColour}\n"
			read url; echo
			echo -e "${blueColour}[*] Doing whatweb ... ${endColour}\n"
			whatweb $url
			options

		elif [ $value == "3" ]; then
			clear
			echo -e "\n${blueColour}[*] What is the port of the page to be fuzzing?${endColour}\n"
			echo -e "\n${yellowColour}Available ports: $ports${endColour}\n"
			read one_port; echo
			sudo nmap --script http-enum -p$one_port $ip
			options

		elif [ $value == "4" ]; then
			clear
			echo -e "\n${redColour}[!] Comming out ...${endColour}"
			echo -e "\n${greenColour}   Have a nice day :)${endColour}\n"
			exit 0

		else
			echo -e "\n${redColour}An error occurred while executing this program${endColour}"
			exit 1
		fi

	done

fi
