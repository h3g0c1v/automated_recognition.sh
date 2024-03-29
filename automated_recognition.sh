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
protocol="http"

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
	echo -e "\n${blueColour}[*] Choose an option${endColour}\n"
	echo -e "\t${blueColour}Do ping ${endColour}${yellowColour}                      [0]${endColour}"
	echo -e "\t${blueColour}Reconnaissance with nmap${endColour}${yellowColour}      [1]${endColour}"
	echo -e "\t${blueColour}Your victime has a website${endColour}${yellowColour}    [2]${endColour}"
	echo -e "\t${blueColour}Simple fuzzing on a website${endColour}${yellowColour}   [3]${endColour}"
	echo -e "\t${blueColour}Exit${endColour}${yellowColour}                          [4]${endColour}"
	echo -e "\n${blueColour}[*] What do you want to do now?${endColour}${yellowColour}       [?]${endColour}\n"
	read value
}

function wfuzz_options_extension(){

	echo -e "\n${blueColour}[*] Do you want to fuzz with a expecific extension?${endColour}"
	echo -e "\n\t${blueColour}No${endColour}${yellowColour}                               [1]${endColour}"
	echo -e "\t${blueColour}Yes${endColour}${yellowColour}                              [2]${endColour}"
	echo -e "\t${blueColour}I want a dictionary extensions${endColour}${yellowColour}   [3]${endColour}\n"
	echo -e "${blueColour}[*] What do you want to do now?${endColour}${yellowColour}          [?]${endColour}\n"
	read wfuzz_extension
}

function fuzz_options(){

	echo -e "\n${blueColour}[*] What do you want to fuzz with?${endColour}"
	echo -e "\n\t${blueColour}Nmap${endColour}${yellowColour}			[1]${endColour}"
	echo -e "\t${blueColour}Wfuzz${endColour}${yellowColour}			[2]${endColour}"
	echo -e "\t${blueColour}Gobuster${endColour}${yellowColour} 	        [3]${endColour}"
	echo -e "\t${blueColour}Return to options${endColour}${yellowColour}       [4]${endColour}"
	echo -e "\n${blueColour}[*] What do you want to do now?${endColour}${yellowColour}	[?]${endColour}\n"
	read fuzz_value
}

function port_to_fuzz(){
	echo -e "\n${blueColour}[*] What is the port of the page to be fuzzing?${endColour}"
	echo -e "\n${yellowColour}\t[*] Available ports: $ports${endColour}\n"
	read one_port; echo
}

#Ping function
function do_ping(){
	echo -e "\n${blueColour}[*] Sending an ICMP trace to IP: ${endColour}${yellowColour}$ip${endColour}\n"
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

function http_or_https(){
	echo -e "\n${blueColour}[*] Is your website http or https?${endColour}"
	echo -e "\n\t${blueColour}http	${endColour}${yellowColour}		[1]${endColour}"
	echo -e "\t${blueColour}https  ${endColour}${yellowColour}			[2]${endColour}"
	echo -e "\n${blueColour}[*] Which option do you choose?	${endColour}${yellowColour}[?]${endColour}\n"	
	read http_s
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

	if [[ $ip =~  ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];then

		options

		while [ $value -gt 4 ] || [ $value -lt 0 ]; do
			echo -e "\n${redColour}Enter a number that is in the options${endColour}"
			options
		done

		while [ $value == "0" ] || [ $value == "1" ] || [ $value == "2" ] || [ $value == "3" ] || [ $value == "4" ]; do

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
				echo -e "\n${blueColour}[*] Enter the URL of the website (If it is a port other than 80 or 443 enter the corresponding port)${endColour}\n"
				read url; echo
				echo -e "${blueColour}[*] Doing whatweb to website: ${endColour}${yellowColour}$url${endColour}\n"
				whatweb $url
				options

			elif [ $value == "3" ]; then

				fuzz_options

				while [ $fuzz_value -gt 4 ] || [ $fuzz_value -lt 1 ]; do

					echo -e "\n${redColour}Enter a number between 1-4${endColour}"
					fuzz_options


				done

				if [ $fuzz_value == "1" ]; then
					
					port_to_fuzz

					echo -e "${blueColour}[*] Doing nmap discovery fuzz${endColour}\n"
					sudo nmap --script http-enum -p$one_port $ip

				elif [ $fuzz_value == "2" ]; then

					port_to_fuzz

					echo -e "${blueColour}[*] What dictionary do you want to use?${endColour}\n"
					read wfuzz_dictionary

					while [ ! -f $wfuzz_dictionary ]; do

						echo -e "\n${redColour}[!] Introduce valid dictionary${endColour}"
						echo -e "\n${blueColour}[*] What dictionary do you want to use?${endColour}\n"
						read wfuzz_dictionary
											
					done
					
					if [ -f $wfuzz_dictionary ]; then
						
						http_or_https

						while [ "$http_s" != "1" ] && [ "$http_s" != "2" ]; do
												
							echo -e "\n${redColour}[!] Choose an option between 1-2${endColour}"
							http_or_https

						done

						if [ $http_s == "1" ]; then

							http=$protocol

						fi

						if [ http_s == "2" ]; then

							https=$protocol
						
						fi

						wfuzz_options_extension
										
						while [ $wfuzz_extension -gt "3" ] || [ $wfuzz_extension -lt "1" ]; do

							echo $wfuzz_extension
							echo -e "\n${redColour}Choose an option between 1-3${endColour}\n"
							wfuzz_options_extension

						done

						if [ $wfuzz_extension == "1" ] || [ $wfuzz_extension == "2" ] || [ $wfuzz_extension == "3" ]; then
							
							if [ $wfuzz_extension == "1" ]; then

								clear
								echo -e "\n${blueColour}[*] Doing fuzz${endColour}\n"
								wfuzz -c -t 200 --hc=404 -w $wfuzz_dictionary $protocol://$1/FUZZ 2>/dev/null
							
							elif [ $wfuzz_extension == "2" ]; then

								echo -e "\n${blueColour}[*] Expecific the extension that you have to fuzz${endColour}\n"
								read extension
								clear
								echo -e "\n${blueColour}[*] Doing fuzz with extension: ${endColour}${yellowColour}$extension${endColour}\n"
								wfuzz -c -t 200 --hc=404 -w $wfuzz_dictionary $protocol://$1/FUZZ.$extension 2>/dev/null

							elif [ $wfuzz_extension == "3" ]; then

								echo -e "\n${blueColour}[*] Expecific the dictionary extensions${endColour}\n"
								read dictionary_extensions
								
								while [ ! -f $dictionary_extensions ]; do

									echo -e "\n${redColour}[*] Introduce a valid file${endColour}"
									echo -e "\n${blueColour}[*] Expecific the dictionary extensions${endColour}\n"
									read dictionary_extensions

								done

								if [ -f $dictionary_extensions ]; then
									
									clear
									echo -e "\n${blueColour}[*] Doing fuzz with extensions: ${endColour}${yellowColour}$(cat $dictionary_extensions | awk '{print $1}' FS='/' | xargs | tr ' ' ',')${endColour}\n"
									wfuzz -c -t 200 --hc=404 -w $wfuzz_dictionary -w $dictionary_extensions $protocol://$1/FUZZ.FUZ2Z 2>/dev/null

								fi

							fi

						fi
					fi

				elif [ $fuzz_value == "3" ]; then

					port_to_fuzz
					echo -e "${blueColour}[*] What dictionary do you want to use?${endColour}\n"
					read gobuster_dictionary; echo

					while [ ! -f $gobuster_dictionary ]; do

						echo -e "${redColour}[!] Introduce a valid file${endColour}"
						echo -e "\n${blueColour}[*] What dictionary do you want to use?${endColour}\n"
						read gobuster_dictionary; echo
					done

					while [ -f $gobuster_dictionary ]; do

						clear
						echo -e "\n[*] Doing fuzz"
						gobuster dir -u $1 -w $gobuster_dictionary

					done

				elif [ $fuzz_value == "4" ]; then

					clear
					options

				fi

			elif [ $value == "4" ]; then

				echo -e "\n${redColour}[!] Comming out ...${endColour}"
				echo -e "\n${greenColour}   Have a nice day :)${endColour}\n"
				exit 0

			else
				echo -e "\n${redColour}An error occurred while executing this program${endColour}"
				exit 1
			fi

		done
	
	else

		echo -e "\n${redColour}[!] Introduce a valid IP${endColour}\n"
		exit 1

	fi

fi
