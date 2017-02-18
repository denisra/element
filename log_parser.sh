#!/bin/sh

IN_FILE="element_log.log"
OUT_FILE="/tmp/$(date +"%F_%T")_element.log"
JIRA_URL="http://192.168.0.145:8080/rest/api/2/issue/"
JIRA_USR="admin"
JIRA_PWD="admin"
JIRA_PROJECT="10000"
JIRA_ISSUE_TYPE="Bug"


usage() {
	echo -e "\n\nGiven a timestamp, extracts the contents of $IN_FILE from 2 minutes"
	echo -e "\nbefore to 2 minutes after and saves the results to $OUT_FILE"
	echo -e "\nUsage:\n\t$0 timestamp"
	echo -e "\n\ttimestamp:\tTimestamp in the format "MM/DD/YYYY HH:mm:ss""
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

BEG_TIME=$(date -d "$FAIL_TIME - 2 minutes" +"%b%e %T %Y")
END_TIME=$(date -d "$FAIL_TIME + 2 minutes" +"%b%e %T %Y")

sed -n "/$BEG_TIME/,/$END_TIME/p" $IN_FILE > $OUT_FILE

echo "Results can be found at ${OUT_FILE}"


post_data() {

cat <<EOF
{"fields": {"project": {"id": "${JIRA_PROJECT}" }, "summary": "A failure occured at ${FAIL_TIME}.", "description": "There was a failure with our app at ${FAIL_TIME}. The log file within that timeframe has been attached to this issue.", "issuetype": {"name": "${JIRA_ISSUE_TYPE}"}}}
EOF
}


RES=$(curl -s -u "${JIRA_USR}":"${JIRA_PWD}" -X POST --data "$(post_data)" -H "Content-Type: application/json" "${JIRA_URL}")
ISSUE_ID=$(echo "${RES}" | python3 -mjson.tool| grep id | awk 'BEGIN{FS="\""}{print $4}')

if [[ -n "${ISSUE_ID}" ]]
then
    echo "Issue ${ISSUE_ID} has been created"
    FNAME=$(curl -s -u "${JIRA_USR}":"${JIRA_PWD}" -X POST -H "X-Atlassian-Token: no-check" -F "file=@${OUT_FILE}" "${JIRA_URL}${ISSUE_ID}/attachments/" | python3 -mjson.tool| grep filename | awk 'BEGIN{FS="\""}{print $4}')
    if [[ -n "${FNAME}" ]]
    then
        echo "File: ${FNAME} has been attached to issue #${ISSUE_ID}"
    else
        echo "ERROR attaching ${OUT_FILE} to issue #${ISSUE_ID}"
    fi
else
    echo -e "ERROR: Unable to create a ticket.\n${RES}"
fi

