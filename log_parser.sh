#!/bin/sh

IN_FILE=element_log.log
OUT_FILE="/tmp/$(date +'%F_%T')_element.log"

usage() {
	echo -e "\n\nGiven a timestamp, extracts the contents of $IN_FILE from 2 minutes"
	echo -e "\nbefore to 2 minutes after and saves the results to $OUT_FILE"
	echo -e "\nUsage:\n\t$0 timestamp"
	echo -e "\n\ttimestamp:\tTimestamp in the format 'MM/DD/YYYY HH:mm:ss'"
	}


if [ $# -ne 1 ]
then
	usage
	exit 1
fi

case $1 in
	-h|--help)
		usage
		exit 0
		;;
	
	-*)
		echo "ERROR: unknown argument \"$1\""
		usage
		exit 1
		;;
	*)
		FAIL_TIME=$(date -d "$1")
		if [ $? -ne 0 ]
		then
			echo "ERROR: invalid timestamp format \"$1\""
		else		
			break
		fi
		;;
esac

BEG_TIME=$(date -d "$FAIL_TIME - 2 minutes" +'%b%e %T %Y')
END_TIME=$(date -d "$FAIL_TIME + 2 minutes" +'%b%e %T %Y')

sed -n "/$BEG_TIME/,/$END_TIME/p" $IN_FILE > $OUT_FILE
