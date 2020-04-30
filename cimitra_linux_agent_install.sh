#!/bin/bash
###########################################
# cimitra_agent_install.sh                #
# Author: Tay Kratzer - tay@cimitra.com   #
# Version: 1.0                            #
# Modify date: 4/30/2020                  #
###########################################
# Cimitra Agent Installation Script

declare -i ROOT_USER=`whoami | grep -c "root"`
declare -i SYSTEMD_INSTALL=0
declare -i UNINSTALL=0
declare -i SHOW_HELP=0
declare -i DEBUG=0
declare -i CIMITRA_AGENT_IN_SET=0
declare CIMITRA_AGENT_IN=`hostname | tr [a-z] [A-Z]`
declare -i CIMITRA_SERVER_ADMIN_PASSWORD_SPECIFIED=0
declare -i CIMITRA_SERVER_ADDRESS_SPECIFIED=0
declare CIMITRA_SERVER_ADDRESS="127.0.0.1"
declare -i CIMITRA_SERVER_PORT_SPECIFIED=0
declare CIMITRA_SERVER_PORT="443"
declare -i CIMITRA_SERVER_ADMIN_SPECIFIED=0
declare CIMITRA_SERVER_ADMIN_ACCOUNT="admin@cimitra.com"
declare -i CIMITRA_SERVER_ADMIN_PASSWORD_SPECIFIED=0
declare CIMITRA_SERVER_ADMIN_PASSWORD="changeme"
declare -i PROCEED_WITH_AGENT_INSTALL=0
declare -i AGENT_INSTALL_PROCESS_SUCCESS=0
declare -i CIMITRA_AGENT_IN_SET_TEST=0
declare TEMP_FILE_DIRECTORY="/var/tmp"

while getopts "a:p:u:c:n:svhU" opt; do
  case ${opt} in
    r) UNINSTALL=1
	DEBUG=1
      ;;
    a) CIMITRA_SERVER_ADDRESS="$OPTARG"
	CIMITRA_SERVER_ADDRESS_SPECIFIED=1
      ;;
    p) CIMITRA_SERVER_PORT="$OPTARG"
	CIMITRA_SERVER_PORT_SPECIFIED=1
      ;;
    u) CIMITRA_SERVER_ADMIN_ACCOUNT="$OPTARG"
	CIMITRA_SERVER_ADMIN_ACCOUNT_SPECIFIED=1
      ;;
    c) CIMITRA_SERVER_ADMIN_PASSWORD="$OPTARG"
	CIMITRA_SERVER_ADMIN_PASSWORD_SPECIFIED=1
      ;;
    s) SYSTEMD_INSTALL=1
      ;;

    n) CIMITRA_AGENT_IN="$OPTARG"
	CIMITRA_AGENT_IN_SET=1
      ;;
    v) DEBUG=1
      ;;
    h) SHOW_HELP="1"
      ;;
  esac
done

CIMITRA_SERVER_ADDRESS=$1
CIMITRA_SERVER_PORT=$2
CIMITRA_SERVER_ADMIN_ACCOUNT=$3
CIMITRA_SERVER_ADMIN_PASSWORD=$4
SYSTEMD_INSTALL=`echo $@ | grep -c systemd`
CIMITRA_AGENT_IN_SET_TEST=`echo $@ | grep -c "name="`

if [ $CIMITRA_AGENT_IN_SET_TEST -eq 1 ]
then
CIMITRA_AGENT_IN=`echo $@ | awk -F "name=" '{printf $2}'`
CIMITRA_AGENT_IN_SET="1"
fi


if [ $SHOW_HELP -eq 1 ]
then
echo ""
echo "--- Script Help ---"
echo ""
echo "Install Cimitra Agent on Linux"
echo ""
echo "$0 -a <cimitra server address> -p <cimtra server port> -u <admin level user> -c <password for user>"
echo ""
echo "When installing the Cimitra Agent, install as a systemd service"
echo ""
echo "$0 -s ..."
echo ""
echo "Give the Cimitra Agent a Specific Name"
echo ""
echo "$0 -n ..."
echo ""
echo "Show Help"
echo ""
echo "$0 -h"
echo ""
echo "-------------------"
echo ""
echo "$0 -r"
echo ""
echo "r = Remove Cimitra Agent (Uninstall)"
echo ""
echo "-------------------"
exit 0
fi


function CALL_ERROR_EXIT()
{
ERROR_MESSAGE="$1"
ERROR_MESSAGE="  ${ERROR_MESSAGE}  "
echo ""
if [ -t 0 ]
then
echo "$(tput setaf 1)ERROR:$(tput setab 7)${ERROR_MESSAGE}$(tput sgr 0)"
else
echo "ERROR:${ERROR_MESSAGE}"
fi
echo ""
exit 1
}

function CALL_ERROR()
{
ERROR_MESSAGE="$1"
ERROR_MESSAGE="  ${ERROR_MESSAGE}  "
echo ""
if [ -t 0 ]
then
echo "$(tput setaf 1)ERROR:$(tput setab 7)${ERROR_MESSAGE}$(tput sgr 0)"
else
echo "ERROR:${ERROR_MESSAGE}"
fi
echo ""
}

function CALL_INFO()
{
INFO_MESSAGE="$1"
INFO_MESSAGE="  ${INFO_MESSAGE}  "
echo ""
if [ -t 0 ]
then
echo "$(tput setaf 2)$(tput setab 4)INFO:$(tput setaf 4)$(tput setab 7)${INFO_MESSAGE}$(tput sgr 0)"
else
echo "INFO:${INFO_MESSAGE}"
fi
echo ""
}

function CALL_COMMAND()
{
INFO_MESSAGE="$1"
INFO_MESSAGE="  ${INFO_MESSAGE}  "
echo ""
if [ -t 0 ]
then
echo "$(tput setaf 2)$(tput setab 4)COMMAND:$(tput setaf 4)$(tput setab 7)${INFO_MESSAGE}$(tput sgr 0)"
else
echo "COMMAND:${INFO_MESSAGE}"
fi
echo ""
}



function CONNECT_TEST()
{

if [ $DEBUG -eq 1 ]
then
echo "IN: $FUNCNAME"
fi

if [ $DEBUG -eq 1 ]
then
echo "cat < /dev/tcp/${CIMITRA_SERVER_ADDRESS}/${CIMITRA_SERVER_PORT}"
cat < /dev/tcp/${CIMITRA_SERVER_ADDRESS}/${CIMITRA_SERVER_PORT} &
else
{
cat < /dev/tcp/${CIMITRA_SERVER_ADDRESS}/${CIMITRA_SERVER_PORT} &
} 2> /dev/null
fi

CONNECTION_PROCESS=$!

declare -i CONNECTION_PROCESS_WORKED=`ps -aux | grep ${CONNECTION_PROCESS} | grep -c "cat"`

if [ $CONNECTION_PROCESS_WORKED -eq 0 ]
then
CALL_ERROR "Cannot Connect to Server: ${CIMITRA_SERVER_ADDRESS} at Port: ${CIMITRA_SERVER_PORT}"
return 1
else
return 0
fi

}

function ESTABLISH_CIMITRA_API_SESSION()
{

if [ $DEBUG -eq 1 ]
then
echo "IN: $FUNCNAME"
fi

CALL_INFO "Establishing Connection to Cimitra Server"

CALL_INFO "Server: ${CIMITRA_SERVER_ADDRESS} | Port: ${CIMITRA_SERVER_PORT}"

BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api" 

ENDPOINT="/users/login" 

URL="${BASEURL}${ENDPOINT}" 

DATA="{\"email\":\"${CIMITRA_SERVER_ADMIN_ACCOUNT}\",\"password\": \"${CIMITRA_SERVER_ADMIN_PASSWORD}\"}" 


if [ $DEBUG -eq 1 ]
then
RESPONSE=`curl -k -f -H "Content-Type:application/json" -X POST ${URL} --data "$DATA"`
else
{
RESPONSE=`curl -k -f -H "Content-Type:application/json" -X POST ${URL} --data "$DATA"`
} 2> /dev/null
fi



declare -i STATUS=`echo "${RESPONSE}" | grep -c ',\"homeFolderId\":\"'` 

if [ $DEBUG -eq 1 ]
then

	if [ ${STATUS} -eq 0 ] 
	then
	CALL_ERROR "Cannot Get a Valid Connection to the Cimitra Server"
	else
	CALL_INFO "Got a Valid Connection to the Cimitra Server"
	fi

else
	if [ ${STATUS} -eq 0 ] 
	then
	CALL_ERROR "Cannot Get a Valid Connection to the Cimitra Server"
	fi

fi

if [ ${STATUS} -eq 0 ] 
then
PROCEED_WITH_AGENT_INSTALL="1"
return 1
fi 

CIMITRA_API_SESSION_TOKEN=`echo "${RESPONSE}" | awk -F \"token\":\" '{printf $2}' | awk -F \" '{printf $1}'`

CALL_INFO "Established API Connection to Cimitra Server"
}

function CREATE_PAIRED_CIMITRA_AGENT()
{

if [ $DEBUG -eq 1 ]
then
echo "IN: $FUNCNAME"
fi

if [ $DEBUG -eq 1 ]
then

	if [ $PROCEED_WITH_AGENT_INSTALL -ne 0 ]
	then
	echo "Agent Install Process Not Proceeding"
	else
	echo "Agent Install Process Proceeding"
	fi

fi

if [ $PROCEED_WITH_AGENT_INSTALL -ne 0 ]
then
return 1
fi

AGENT_NAME="${CIMITRA_AGENT_IN}"

BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api"
 
ENDPOINT="/agent" 

URL="${BASEURL}${ENDPOINT}" 

CALL_INFO "Creating a new Cimitra Agent by the Name of: ${AGENT_NAME}"

JSON_TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp.json"

SERVER_HOST_NAME=`hostname`

THE_DESCRIPTION="Cimitra Agent Deployed to Server: ${SERVER_HOST_NAME}\nIf you need to install the agent again folllow these 4 Simple Steps\n1. Download the Cimitra Agent and put it on the Linux server: ${AGENT_NAME} \n2. Make the cimagent file executable: chmod +x ./cimagent\n3. Install the Cimitra Agent with the command: ./cimagent c\n4. Start the Cimitra Agent with the command: cimitra start"

echo "{
    \"name\": \"${AGENT_NAME}\",
    \"description\": \"${THE_DESCRIPTION}\",
    \"platform\": \"linux\",
    \"match_regex\":  \"node01\"
}" 1> ${JSON_TEMP_FILE_ONE} 

if [ $DEBUG -eq 1 ]
then
declare RESPONSE=`curl -k ${CURL_OUTPUT_MODE} -H 'Accept: application/json' \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-X POST ${URL} -d @${JSON_TEMP_FILE_ONE}  \
-H "Content-Type: application/json"`
else
{
declare RESPONSE=`curl -k ${CURL_OUTPUT_MODE} -H 'Accept: application/json' \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-X POST ${URL} -d @${JSON_TEMP_FILE_ONE}  \
-H "Content-Type: application/json"`
} 1> /dev/null 2> /dev/null
fi

rm ${TEMP_FILE_DIRECTORY}/$$.tmp.agent.json 2> /dev/null

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp"

TEMP_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.2.tmp"

echo "$RESPONSE" 1> ${TEMP_FILE_ONE}

sed -e 's/[}"]*\(.\)[{"]*/\1/g;y/,/\n/' < ${TEMP_FILE_ONE} > ${TEMP_FILE_TWO}

declare -i ERROR_STATE=`cat ${TEMP_FILE_TWO} | grep -c "error"`

if [ $DEBUG -eq 1 ]
then

	if [ $ERROR_STATE -gt 0 ]
	then
	echo "Error State"
	cat ${TEMP_FILE_TWO}
	fi

fi

if [ $ERROR_STATE -gt 0 ]
then
rm ${TEMP_FILE_ONE} 2> /dev/null
rm ${TEMP_FILE_TWO} 2> /dev/null
return 1
fi

# CALL_INFO "Created a new Cimitra Agent by the Name of: ${AGENT_NAME}"


CIMITRA_PAIRED_AGENT_ID=`cat ${TEMP_FILE_TWO} | grep "_id:" | awk -F : '{printf $2}'`

if [ $DEBUG -eq 1 ]
then
echo "CIMITRA_PAIRED_AGENT_ID = $CIMITRA_PAIRED_AGENT_ID"
fi


rm ${TEMP_FILE_ONE} 2> /dev/null

rm ${TEMP_FILE_TWO} 2> /dev/null

}



function DOWNLOAD_AND_INSTALL_CIMITRA_AGENT()
{

if [ $DEBUG -eq 1 ]
then
echo "IN: $FUNCNAME"
fi

if [ $DEBUG -eq 1 ]
then
echo "IN: $FUNCNAME"
fi

if [ $PROCEED_WITH_AGENT_INSTALL -ne 0 ]
then
return
fi

CIMITRA_AGENT_BINARY_FILE="/usr/bin/cimagent"

declare -i CIMITRA_AGENT_INSTALLED=`test -f ${CIMITRA_AGENT_BINARY_FILE} ; echo $?`

# If an agent isn't installed....
if [ $CIMITRA_AGENT_INSTALLED -eq 1 ]
then

BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api"
 
ENDPOINT="/agent" 

URL="${BASEURL}${ENDPOINT}" 

# Look for all agents

if [ $DEBUG -eq 1 ]
then

declare RESPONSE=`curl -k ${CURL_OUTPUT_MODE} -H 'Accept: application/json' \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-X GET ${URL}`

else

{
declare RESPONSE=`curl -k ${CURL_OUTPUT_MODE} -H 'Accept: application/json' \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-X GET ${URL}`
} 1> /dev/null 2> /dev/null

fi



TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp"

TEMP_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.2.tmp"

echo "$RESPONSE" 1> ${TEMP_FILE_ONE}

sed -e 's/[}"]*\(.\)[{"]*/\1/g;y/,/\n/' < ${TEMP_FILE_ONE} > ${TEMP_FILE_TWO}

CIMITRA_AGENT_IN_SET=1

SERVER_HOSTNAME=`hostname`
	
	declare -i CIMITRA_AGENT_NAME_EXISTS=`cat ${TEMP_FILE_TWO} | grep -icw "name:${AGENT_NAME}"`

if [ $DEBUG -eq 1 ]
then
echo "CIMITRA_AGENT_NAME_EXISTS = $CIMITRA_AGENT_NAME_EXISTS"
fi


	if [ $CIMITRA_AGENT_NAME_EXISTS -gt 0 ]
	then
	CIMITRA_PAIRED_AGENT_ID=`cat ${TEMP_FILE_TWO} | grep -iwB 1 "name:${AGENT_NAME}" | head -1 | awk -F ":" '{printf $2}'`

		if [ $DEBUG -eq 1 ]
		then
		echo "CIMITRA_PAIRED_AGENT_ID = $CIMITRA_PAIRED_AGENT_ID"
		fi
	else

		if [ $DEBUG -eq 1 ]
		then
		echo "Calling Function CREATE_PAIRED_CIMITRA_AGENT"
		fi

	CREATE_PAIRED_CIMITRA_AGENT
	fi		



fi

if [ $CIMITRA_AGENT_INSTALLED -eq 0 ]
then
# echo "AGENT IS INSTALLED...Let's keep checking"
# Determine if the installed Cimitra Agent is actually still registered in Cimitra


CIMITRA_BINARY_AGENT_ID=`sudo ${CIMITRA_AGENT_BINARY_FILE} | grep -iA1 "agentid" | tail -1 | awk -F "= " '{printf $2}'`

if [ $DEBUG -eq 1 ]
then
echo "CIMITRA_BINARY_AGENT_ID = $CIMITRA_BINARY_AGENT_ID"
fi


BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api"
 
ENDPOINT="/agent" 

URL="${BASEURL}${ENDPOINT}" 

if [ $DEBUG -eq 1 ]
then

declare RESPONSE=`curl -k ${CURL_OUTPUT_MODE} -H 'Accept: application/json' \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-X GET ${URL}`

else

{
declare RESPONSE=`curl -k ${CURL_OUTPUT_MODE} -H 'Accept: application/json' \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-X GET ${URL}`
} 1> /dev/null 2> /dev/null

fi

TEMP_FILE_ONE="${TEMP_FILE_DIRECTORY}/$$.1.tmp"

TEMP_FILE_TWO="${TEMP_FILE_DIRECTORY}/$$.2.tmp"

echo "$RESPONSE" 1> ${TEMP_FILE_ONE}

sed -e 's/[}"]*\(.\)[{"]*/\1/g;y/,/\n/' < ${TEMP_FILE_ONE} > ${TEMP_FILE_TWO}

SEARCH_FOR="${CIMITRA_BINARY_AGENT_ID}"

declare -i CIMITRA_AGENT_ID_EXISTS=`cat ${TEMP_FILE_TWO} | grep -icw "_id:${SEARCH_FOR}"`


if [ $DEBUG -eq 1 ]
then
echo "CIMITRA_AGENT_ID_EXISTS = $CIMITRA_AGENT_ID_EXISTS"
fi

	if [ $CIMITRA_AGENT_ID_EXISTS -gt 0 ]
	then
	CIMITRA_PAIRED_AGENT_ID=`cat ${TEMP_FILE_TWO} | grep -iw  "_id:${SEARCH_FOR}" | head -1 | awk -F ":" '{printf $2}'`
	CIMITRA_PAIRED_AGENT_NAME=`cat ${TEMP_FILE_TWO} | grep -A 1 ${SEARCH_FOR} | tail -1 | awk -F ":" '{printf $2}'`
	CIMITRA_PAIRED_AGENT_NAME_LOWER=`echo "${CIMITRA_PAIRED_AGENT_NAME}" | tr [A-Z] [a-z]`
	

		if [ $DEBUG -eq 1 ]
		then
		echo "CIMITRA_PAIRED_AGENT_ID = $CIMITRA_PAIRED_AGENT_ID"
		echo "CIMITRA_PAIRED_AGENT_NAME = $CIMITRA_PAIRED_AGENT_NAME"
		fi

	rm ${TEMP_FILE_ONE} 2> /dev/null
	rm ${TEMP_FILE_TWO} 2> /dev/null
	return 0

		
	else



		AGENT_NAME="${CIMITRA_AGENT_IN}"

		if [ $DEBUG -eq 1 ]
		then
		echo "AGENT_NAME = $AGENT_NAME"
		fi


	declare -i CIMITRA_AGENT_NAME_EXISTS=`cat ${TEMP_FILE_TWO} | grep -icw "name:${AGENT_NAME}"`


		if [ $CIMITRA_AGENT_NAME_EXISTS -gt 0 ]
		then
			CIMITRA_PAIRED_AGENT_ID=`cat ${TEMP_FILE_TWO} | grep -iwB 1 "name:${AGENT_NAME}" | head -1 | awk -F ":" '{printf $2}'`
		else
			echo ""
			CALL_INFO "Process: Replacing the existing Cimitra Agent"
			echo ""
			rm ${TEMP_FILE_ONE} 2> /dev/null
			rm ${TEMP_FILE_TWO} 2> /dev/null
			CREATE_PAIRED_CIMITRA_AGENT
		fi		


	fi

fi

rm ${TEMP_FILE_ONE} 2> /dev/null

rm ${TEMP_FILE_TWO} 2> /dev/null

DATA="{\"host\": \"${CIMITRA_SERVER_ADDRESS}\",\"port\": \"${CIMITRA_SERVER_PORT}\",\"root\": \"/api\",\"arch\": \"x64\"}" 

BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api"

ENDPOINT="/agent/${CIMITRA_PAIRED_AGENT_ID}/download"

URL="${BASEURL}${ENDPOINT}" 

CIMAGENT_FILE="${TEMP_FILE_DIRECTORY}/cimagent"

# echo "CIMITRA_PAIRED_AGENT_ID = $CIMITRA_PAIRED_AGENT_ID"

# echo "DATA = $DATA"

if [ $DEBUG -eq 1 ]
then
sudo rm ${CIMAGENT_FILE} 
else
	if [ $ROOT_USER -eq 1 ]
	then
	rm ${CIMAGENT_FILE} 2> /dev/null
	else
	sudo rm ${CIMAGENT_FILE}
	fi

fi



CALL_INFO "Process: Downloading the Cimitra Agent File (this may take a little bit...)"
echo "-----------------------------------------------------------------------------"
echo ""

curl -k  \
-H "Accept: application/json" \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-H "Cache-Control: no-cache" \
-X POST ${URL} \
-H "Content-Type: application/json" \
--data "${DATA}" -o ${CIMAGENT_FILE} 

echo ""
echo "-----------------------------------------------------------------------------"


declare -i CIMAGENT_FILE_EXISTS=`test -f ${CIMAGENT_FILE} ; echo $?`

if [ $CIMAGENT_FILE_EXISTS -ne 0 ]
then
echo ""
CALL_ERROR "Could not Download the Cimitra Agent File"
return
fi

AGENT_INSTALL_PROCESS_SUCCESS="1"

# CALL_COMMAND "sudo chmod +x ${CIMAGENT_FILE}"

sudo chmod +x ${CIMAGENT_FILE}

# CALL_COMMAND "cd ${TEMP_FILE_DIRECTORY}"

cd ${TEMP_FILE_DIRECTORY}

if [ $DEBUG -eq 1 ]
then
sudo ./cimagent
else
	if [ $ROOT_USER -eq 1 ]
	then
	sudo ./cimagent 1> /dev/null 2> /dev/null 
	else
	sudo ./cimagent
	fi
fi

DOWNLOAD_FILE_STATE=`echo $?`

if [ $DOWNLOAD_FILE_STATE -ne 0 ]
then
AGENT_INSTALL_PROCESS_SUCCESS="0"
	if [ $ROOT_USER -eq 1 ]
	then
	sudo rm ${CIMAGENT_FILE} 2> /dev/null
	else
	sudo rm ${CIMAGENT_FILE}
	fi

echo ""
echo "Error: The Cimitra Agent Could Not Be Downloaded"
echo ""
echo "NOTE: Generally this means that the server that hosts..."
echo ""
echo "... the Cimitra Server Docker Image needs more memory allocated"
echo ""
return 1

BASEURL="http://${CIMITRA_SERVER_API_ADDRESS}:${CIMITRA_SERVER_API_PORT}"

URL="${BASEURL}${ENDPOINT}" 

echo ""
CALL_INFO "Process: Downloading the Cimitra Agent File (this may take a little bit...)"
echo ""
echo "-----------------------------------------------------------------------------"
echo ""

curl -k  \
-H "Authorization: Bearer ${CIMITRA_API_SESSION_TOKEN}" \
-X POST ${URL} \
-H "Content-Type: application/json" \
--data "${DATA}" -o ${CIMAGENT_FILE} 

echo ""
echo "-----------------------------------------------------------------------------"

else
echo ""
CALL_INFO "Success: Downloaded the Cimitra Agent File"

fi

# CALL_COMMAND "sudo chmod +x ${CIMAGENT_FILE}"

sudo chmod +x ${CIMAGENT_FILE}

if [ $DEBUG -eq 1 ]
then
sudo ./cimagent
else
	if [ $ROOT_USER -eq 1 ]
	then
	sudo ./cimagent 1> /dev/null 2> /dev/null 
	else
	sudo ./cimagent
	fi
fi

DOWNLOAD_FILE_STATE=`echo $?`

if [ $DOWNLOAD_FILE_STATE -eq 0 ]
then

AGENT_INSTALL_PROCESS_SUCCESS="1"

CALL_INFO "Running Agent Install Routine"

if [ $SYSTEMD_INSTALL -eq 0 ]
then

CALL_COMMAND "sudo ./cimagent c"
sudo ./cimagent c

else

CALL_COMMAND "sudo ./cimagent c systemd"

sudo ./cimagent c systemd

fi

	if [ $DEBUG -eq 1 ]
	then
	cimitra stop
	cimitra start  &
	else

		if [ $ROOT_USER -eq 1 ]
		then
		{
		cimitra stop 2> /dev/null 
		cimitra start  &
		} 1> /dev/null 2> /dev/null
		else
		{
		sudo cimitra stop 
		sudo cimitra start &
		} 1> /dev/null 2> /dev/null
		fi
	fi


else
AGENT_INSTALL_PROCESS_SUCCESS="0"
echo ""
echo "Note: Could not Download the Cimitra Agent File"
echo ""
echo "Task: You may need to Download the Cimitra Agent"
echo ""
fi

}

function DOWNLOAD_CIMITRA_APIS()
{

if [ $DEBUG -eq 1 ]
then
echo "IN: $FUNCNAME"
fi


{
cimitra get import & 1> /dev/null 2> /dev/null &
} 1> /dev/null 2> /dev/null 


}


function main()
{
if [ $DEBUG -eq 1 ]
then
echo "IN: $FUNCNAME"
fi

CALL_INFO "1/2: Confirm/Install Cimitra Agent"
CONNECT_TEST
PROCEED_WITH_AGENT_INSTALL=`echo $1`

if [ $PROCEED_WITH_AGENT_INSTALL -ne 0 ]
then
CALL_INFO "Waiting Another 10 Seconds"
CALL_COMMAND "sleep 10"
sleep 10
CONNECT_TEST
PROCEED_WITH_AGENT_INSTALL=`echo $1`

	if [ $PROCEED_WITH_AGENT_INSTALL -ne 0 ]
	then
	CALL_INFO "Waiting Another 10 Seconds One More Time"
	CALL_COMMAND "sleep 10"
	sleep 10
	CONNECT_TEST
	PROCEED_WITH_AGENT_INSTALL=`echo $1`
	fi

fi

if [ $PROCEED_WITH_AGENT_INSTALL -eq 0 ]
then
ESTABLISH_CIMITRA_API_SESSION
fi


CALL_INFO "2/2: Download/Install Cimitra Agent"

if [ $PROCEED_WITH_AGENT_INSTALL -eq 0 ]
then
DOWNLOAD_AND_INSTALL_CIMITRA_AGENT
fi

if [ $AGENT_INSTALL_PROCESS_SUCCESS -eq 1 ]
then
		if [ $ROOT_USER -eq 1 ]
		then
		{
		sudo cimitra stop 1> /dev/null 2> /dev/null &
		} 1> /dev/null 2> /dev/null 
		else
		CALL_COMMAND "sudo cimitra stop"
		sudo cimitra stop
		fi

		

		if [ $ROOT_USER -eq 1 ]
		then
		CALL_COMMAND "cimitra start"
		{
		cimitra start & 1> /dev/null 2> /dev/null &
		} 1> /dev/null 2> /dev/null 

		else
		CALL_COMMAND "sudo cimitra start"

		{
		sudo cimitra start & 1> /dev/null 2> /dev/null &
		} 1> /dev/null 2> /dev/null 

		fi

DOWNLOAD_CIMITRA_APIS

else
CALL_INFO "Cimitra Agent Not Downloaded"
fi

}

function REMOVE_ALL_COMPONENTS()
{

CALL_COMMAND "cimitra stop"

{
cimitra stop & 1> /dev/null 2> /dev/null &
} 1> /dev/null 2> /dev/null 

}


function REMOVE_CIMITRA_API_COMPONENTS()
{
CIMITRA_API_DIR="/var/opt/cimitra/api"

declare -i CD_WORKED=1
cd ${CIMITRA_API_DIR}
CD_WORKED=`echo $?`

if [ $CD_WORKED -ne 0 ]
then
return 1
fi

declare -i CURRENT_PATH=`pwd | grep -c ${CIMITRA_API_DIR}`

if [ $CURRENT_PATH -ne 1 ]
then
return 1
fi

rm -rv ./import 2> /dev/null

}

function REMOVE_CIMITRA_AGENT()
{
CIMITRA_AGENT_BIN_FILE="/usr/bin/cimagent"
CIMITRA_AGENT_SYM_FILE="/usr/bin/cimitra"
CIMITRA_AGENT_SCRIPT_FILE="/etc/init.d/cimitra"

rm -v ${CIMITRA_AGENT_BIN_FILE}
rm -v ${CIMITRA_AGENT_SYM_FILE}
rm -v ${CIMITRA_AGENT_SCRIPT_FILE}
}


if [ $UNINSTALL -eq 0 ]
then
main
else
REMOVE_ALL_COMPONENTS
REMOVE_CIMITRA_API_COMPONENTS
REMOVE_CIMITRA_AGENT
fi
