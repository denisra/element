#!/bin/sh

WORKDIR="/tmp/apache_config_$$"
OUT_DIR="/tmp"
OUT_FILE="${OUT_DIR}/apache_config_$(date +'%F_%T').zip"
LOGS_DIR="/var/log/httpd/"
VAR_DIR="/var/www/html/"
USR="apache"


usage() {
	echo -e "\n\nCopy file(s) from ${LOGS_DIR} and/or ${VAR_DIR}"
	echo -e "to ${OUT_DIR}. If multiple files, a .zip archive will be created."
	echo -e "\nUsage:\n\t$0 arg1 [arg2 ...]"
	echo -e "\n\targ1, arg2, ...:  File(s) or Dir(s) path(s)"
}

if [ $# -lt 1 ]
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
        DIRS=$@
		;;
esac

check_path() {
    if [[ "${1:0:${#LOGS_DIR}}" = "$LOGS_DIR" || "${1:0:${#VAR_DIR}}" = "$VAR_DIR" ]]; then
        echo 1
    else        
        echo 0
    fi
}   


if [[ "$#" -eq 1 && -f "$1" ]]
then
    if [[ $(check_path "$1") -eq 1 ]] 
    then
        su -c "cp $1 ${OUT_DIR}" ${USR}
        echo -e "\n$1 copied to ${OUT_DIR}"
        exit 0
    else
        echo "ERROR: You have no permission to copy $1"
        exit 1
    fi
elif [[ "$#" -eq 1 && ! -e "$1" ]]
then
    echo "ERROR: $1 No such file or directory"
    exit 1
fi


su -c "mkdir -p ${WORKDIR}" ${USR}

FILE_CREATED=0

for d in ${DIRS}
do
    if [[ $(check_path "$d") -eq 1 ]]
    then        
        if [[ -f "$d" ]]
        then
            su -c "cp $d ${WORKDIR}" ${USR}
            FILE_CREATED=1
        elif [[ -d "$d" ]]
        then
            su -c "cp -R $d ${WORKDIR}" ${USR}
            FILE_CREATED=1
        else
            echo "ERROR: $d No such file or directory"
        fi
    else
        echo "ERROR: You have no permission to copy $d"
    fi  
done

if [[ ${FILE_CREATED} -eq 1 ]]
then  
    cd ${WORKDIR}
    su -c "zip -r ${OUT_FILE} * >/dev/null 2>&1" ${USR}
    echo -e "Files were copied to ${OUT_FILE}"
    cd ..
else
    echo "No files were copied"
fi
su -c "rm -Rf ${WORKDIR}" ${USR}

