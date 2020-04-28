#!/bin/bash

httpnum="http://"
if [[ -z $1 ]]; then
	echo "This is the MASTERSCANNER"
	echo "This bash script will run nmap,dirb,theharvester,nikto,etc"
	echo "The scans will be saved to files in the directory where you are running the script"
	echo "Syntax: ./masterscanner.py <IP>"
	echo "EX: ./masterscanner.py 192.168.53.32"
	exit 1
elif [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	ip=$1
	echo "--------------------------------------------------------------------------------"
	echo "                           NOW SCANNING $ip"
	echo "--------------------------------------------------------------------------------"
	nmap -T4 -p- $ip | grep ^[1-9] | tr -d ^{a-z} | tr -d / > openPorts.txt
	cat openPorts.txt | while read line; do
		nmap -T4 -A -p $line $ip >> nmapscan.txt # much faster than running -A on all ports
		if [[ $line == 80 || $line == 443 ]]; then
			nikto -h $ip > niktofile.txt # running nikto against port 80(http)
			fullstring="$httpnum$1"
			echo "$fullstring"
			dirb $fullstring /usr/share/wordlists/dirb/big.txt >dirb.txt
			echo "- Finishing nmap scan.."
			echo "- Finishing nikto scan.."
			echo "- Finishing dirb scan.."
		
			nmap --script dns-brute --script-args dns-brute.domain=foo.com,dns-brute.threads=6,dns-brute.hostlist=./hostfile.txt,newtargets -sS -p $line $ip >> topnmapscriptresults.txt
			nmap --script=http-backup-finder $ip >> topnmapscriptresults.txt
			nmap --script=http-config-backup $ip >> topnmapscriptresults.txt
			nmap --script http-brute -p 80 $ip >> topnmapscriptresults.txt
			nmap --script http-rfi-spider -p $line $ip >> topnmapscriptresults.txt
			nmap -p $line --script http-default-accounts $ip >> topnmapscriptresults.txt
			nmap -p $line --script=ssl-cert $ip >> topnmapscriptresults.txt
			echo "- Finishing nmap script scans.."
			# ABOVE IS A LIST OF NMAP SCRIPTS THAT ARE EFFECTIVE
			#FEEL FREE TO ADD MORE ABOVE THIS LINE
			theharvester -d $ip -b google -l 500 > harvesterresults.txt #harvesterscan 
			echo "- Finishing theharvesterscan.."
			whatweb -v $ip >> pluginsinfo.txt # checks for the plugins for the web app
			echo "- Finishing webapp scan.."
		fi
	done
	rm stash.sqlite
elif ! [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	echo "Please Enter a valid IPV4 address."
	echo "Syntax: ./masterscanner.sh 192.178.32.45"
	exit 1
fi
