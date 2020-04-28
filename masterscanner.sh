#!/bin/bash

httpnum="http://"
echo "This is the MASTERSCANNER"
echo "Syntax: ./masterscanner.py <IP>"
echo "EX: ./masterscanner.py 192.168.53.32"
if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	echo "goodjob"
	nmap -T4 -p- $1 | grep ^[1-9] | tr -d ^{a-z} | tr -d / > port_num.txt
	cat port_num.txt | while read line; do
		nmap -T4 -A -p $line $1 >> portinfo.txt # much faster than running -A on all ports
		if [[ $line == 80 || $line == 443 ]]; then
			nikto -h $1 > niktofile.txt # running nikto against port 80(http)
			fullstring="$httpnum$1"
			echo "$fullstring"
			dirb $fullstring >dirb.txt
			nmap --script dns-brute --script-args dns-brute.domain=foo.com,dns-brute.threads=6,dns-brute.hostlist=./hostfile.txt,newtargets -sS -p $line $1 >> topnmapscriptresults.txt
			nmap --script=http-backup-finder $1 >> topnmapscriptresults.txt
			nmap --script=http-config-backup $1 >> topnmapscriptresults.txt
			nmap --script http-brute -p 80 $1 >> topnmapscriptresults.txt
			nmap --script http-rfi-spider -p $line $1 >> topnmapscriptresults.txt
			nmap -p $line --script http-default-accounts $1 >> topnmapscriptresults.txt
			nmap -p $line --script=ssl-cert $1 >> topnmapscriptresults.txt
		fi
	done
	rm port_num.txt
fi