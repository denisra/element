#!/bin/bash

# Free disk space monitor and email alert
# The script will send an email if the amount of disk space is below $WARN
# If it's below $ERR the $TARGET_FILE will be scp to $BKP_SRV and the file will be removed

FS="/var/log"
TARGET_FILE="${FS}/messages"
FREE_PCT=$(df ${FS} | awk 'NR != 1 {print $5}' | cut -d '%' -f1)
FREE_SPC=$(df -h ${FS} | awk 'NR != 1 {print $4}')
WARN=80
ERR=90
BKP_SRV="192.168.0.145"
BKP_DIR="/tmp"
MAIL_TO="root"
MAIL_SBJ="CRITICAL: $(hostname) is running out of disk space!"
MAIL_MSG="Server $(hostname) is running out of disk space on ${FS}.\nAt $(date) there is only ${FREE_SPC} (${FREE_PCT}%) of free disk space left."



send_mail() {
    
    if $(echo -e "${MAIL_MSG}" | mail -s "${MAIL_SBJ}" ${MAIL_TO})
    then
        echo "Mail sent to ${MAIL_TO}!"
        exit 0
    else
        echo "Error sending mail to ${MAIL_TO}. Check the system logs for more information."
        exit 1
    fi
}

cleanup() {

    if $(scp ${TARGET_FILE} root@"${BKP_SRV}:${BKP_DIR}")
    then
        rm -f ${TARGET_FILE}
        kill -HUP $(cat /var/run/syslogd.pid)
        echo "Cleanup completed!"
        exit 0
    else
        echo "Failed to scp ${TARGET_FILE} to ${BKP_SRV}"
    fi
}


if [[ ${FREE_PCT} -ge ERR ]]
then
    cleanup    
fi

if [[ ${FREE_PCT} -ge WARN ]]
then
    send_mail
fi
