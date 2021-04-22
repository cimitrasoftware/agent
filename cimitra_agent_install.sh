#!/bin/bash  
###########################################
# cimitra_agent_install.sh                #
# Author: Tay Kratzer - tay@cimitra.com   #
# Version: 1.3                            #
# Modify date: 4/22/2021                  #
###########################################
# Cimitra Linux/MacOS Agent Installation Script
PROGRAM_NAME="cimitra_agent_install.sh"
declare -i OS_IS_LINUX=`echo "${OSTYPE}" | grep -ic "linux"`
declare -i OS_IS_MAC=`echo "${OSTYPE}" | grep -ic "darwin"`
declare -i ARM_PROCESSOR=0
declare -i ROOT_USER=`whoami | grep -c "root"`
declare -i SYSTEMD_INSTALL=0
declare -i UNINSTALL=0
declare -i SHOW_HELP=0
declare -i DEBUG=1
declare -i CIMITRA_AGENT_IN_SET=0
declare CIMITRA_AGENT_IN=`hostname | tr [a-z] [A-Z]`
declare -i CIMITRA_SERVER_ADMIN_PASSWORD_SPECIFIED=0
declare -i CIMITRA_SERVER_ADDRESS_SPECIFIED=0
declare CIMITRA_SERVER_ADDRESS="127.0.0.1"
declare -i CIMITRA_SERVER_PORT_SPECIFIED=0
declare CIMITRA_SERVER_PORT="443"
declare -i CIMITRA_SERVER_ADMIN_ACCOUNT_SPECIFIED=0
declare CIMITRA_SERVER_ADMIN_ACCOUNT="admin@cimitra.com"
declare -i CIMITRA_SERVER_ADMIN_PASSWORD_SPECIFIED=0
declare CIMITRA_SERVER_ADMIN_PASSWORD="changeme"
declare -i PROCEED_WITH_AGENT_INSTALL=0
declare -i AGENT_INSTALL_PROCESS_SUCCESS=0
declare -i CIMITRA_AGENT_IN_SET_TEST=0
declare -i CIMITRA_AGENT_NOT_INSTALLED="1"
declare TEMP_FILE_DIRECTORY="/var/tmp"
declare THE_PLATFORM="linux"
declare CIMITRA_PAIRED_AGENT_ID=""
declare CIMITRA_PAIRED_AGENT_NAME=""
declare -i IGNORE_TERMINAL=0
declare -i TERMINAL_TYPE=0
declare -i BACKUP_INSTALL=0

declare -i SUDO_INSTALLED=0
declare SUDO_COMMAND=""
{
sudo -h 1> /dev/null 2> /dev/null
} 1> /dev/null 2> /dev/null

declare -i SUDO_RESPONSE=`echo $?`
if [ $SUDO_RESPONSE -eq 0 ]
then
SUDO_INSTALLED=1
SUDO_COMMAND="sudo"
fi

while getopts "a:p:u:t:c:n:svhU" opt; do
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
    t) SYSTEMD_INSTALL=1
      ;;
	s) IGNORE_TERMINAL=1
      ;;
    n) CIMITRA_AGENT_IN="$OPTARG"
	CIMITRA_AGENT_IN_SET=1
      ;;
    v) DEBUG=1
      ;;
    h) SHOW_HELP="1"
      ;;
  esac
done 2> /dev/null

CIMITRA_SERVER_ADDRESS=$1
CIMITRA_SERVER_PORT=$2
CIMITRA_SERVER_ADMIN_ACCOUNT=$3
CIMITRA_SERVER_ADMIN_PASSWORD=$4

SYSTEMD_INSTALL=`echo $@ | grep -c systemd` 2> /dev/null

BACKUP_INSTALL=`echo $@ | grep -c install_backup` 2> /dev/null

if [ $IGNORE_TERMINAL -eq 0 ]
then
IGNORE_TERMINAL=`echo $@ | grep -c "ignoretty"` 2> /dev/null
fi

CIMITRA_AGENT_IN_SET_TEST=`echo $@ | grep -c "name="` 2> /dev/null

DEBUG=`echo $@ | grep -ic "debug"` 2> /dev/null

function SMILEY_MESSAGE {
message=$1
smiley="\xf0\x9f\x98\x83"
echo -e "$smiley $message"
}

function CHECKMARK_MESSAGE {
message=$1
checkmark="\xE2\x9C\x85"
echo -e "$checkmark $message"
}
	

function DETERMINE_TERMINAL()
{
if [ -t 0 ]
then
TERMINAL_TYPE="0"
else
	if [ $IGNORE_TERMINAL -eq 0 ]
	then
	TERMINAL_TYPE="1"
	fi
fi
}
DETERMINE_TERMINAL


function CALL_INFO()
{
INFO_MESSAGE="$1"
INFO_MESSAGE="  ${INFO_MESSAGE}  "
echo ""
if [ ${TERMINAL_TYPE} -eq 0 ]
then
echo "$(tput setaf 7)$(tput setab 4)INFO:$(tput setaf 4)$(tput setab 7)${INFO_MESSAGE}$(tput sgr 0)"
else
echo "INFO:${INFO_MESSAGE}"
fi
echo ""
}

CALL_INFO "[ Cimitra Agent Install Script - Start ]"

function SEE_IF_HELP_CALLED()
{

if [ $SHOW_HELP -eq 0 ]
then
declare -i SHOW_HELP=`echo "${1}" | grep -ic "help"`
fi

if [ $SHOW_HELP -eq 0 ]
then
declare -i SHOW_HELP=`echo "${1}" | grep -ic "--help"`
fi

if [ $SHOW_HELP -eq 0 ]
then
declare -i SHOW_HELP=`echo "${1}" | grep -ic "--h"`
fi

} 1> /dev/null 2> /dev/null


SEE_IF_HELP_CALLED 2> /dev/null

function HELP_SCREEN()
{
echo ""
echo "--- Script Help ---"
echo ""
echo -e "\e[41mCommon Usage: $0 192.168.1.10 443 admin@cimitra.com myPassword \e[0m"
echo ""
echo "Install Cimitra Agent on Linux/MacOS (No switches, No prompt for credentials method)"
echo ""
echo "$0 <cimitra server address> <cimtra server port> <admin level user> <password for user>"
echo ""
echo "Example:"
echo ""
echo "$0 192.168.1.10 443 admin@cimitra.com myPassword"
echo ""
echo "Install Cimitra Agent on Linux/MacOS  (No switches, Prompt for credentials method)"
echo ""
echo "$0 <cimitra server address> <cimtra server port>"
echo ""
echo "Example:"
echo ""
echo "$0 192.168.1.10 443"
echo ""
echo "Install Cimitra Agent on Linux/MacOS  (Use switches, No prompt for credentials method)"
echo ""
echo "$0 -a <cimitra server address> -p <cimtra server port> -u <admin level user> -c <password for user>"
echo ""
echo "Example:"
echo ""
echo "$0 -a 192.168.1.10 -p 443 -u admin@cimitra.com -c myPassword"
echo ""
echo "Install Cimitra Agent on Linux/MacOS (Use switches, Prompt for credentials method)"
echo ""
echo "$0 -a <cimitra server address> -p <cimtra server port>"
echo ""
echo "Example:"
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
echo -e "\e[41mCommon Usage: $0 192.168.1.10 443 admin@cimitra.com myPassword \e[0m"
echo ""
echo "-------------------"
}

if [ $SHOW_HELP -eq 1 ]
then
HELP_SCREEN
exit 0
fi


if [ $CIMITRA_SERVER_ADMIN_ACCOUNT_SPECIFIED -eq 0 ]
then
CIMITRA_SERVER_ADMIN_ACCOUNT_SPECIFIED=`echo "${CIMITRA_SERVER_ADMIN_ACCOUNT}" | grep -c "@"`
fi

function PROMPT_FOR_SETTINGS()
{
declare -i INPUT_VALID=0
CIMITRA_SERVER_ADMIN_ACCOUNT="admin@cimitra.com"
SUGGESTION="${CIMITRA_SERVER_ADMIN_ACCOUNT}"
echo -e "\033[0;93m\033[44m[ADMIN LEVEL USER ON CIMITRA SERVER]"
echo -e "\033[0;93m\033[44m<Enter to accept, or edit user>\033[0;93m\033[0;92m"
	if [ ${OS_IS_LINUX} = 1 ]
	then
	read -p "Admin Level User: " -e -i ${SUGGESTION} INPUT
	INPUT_VALID=`echo "${INPUT}" | grep -c "@"`
	else
	# MacOS read util doesn't like the -i switch
	read -p "Admin Level User: ${SUGGESTION}" INPUT
	fi

declare -i INPUT_LENGTH=`echo "${INPUT}" | wc -m`


if [ $INPUT_LENGTH -lt 4 ]
then
	# We didn't really get input if it's MacOS
	if [ ${OS_IS_MAC} = 1 ]
	then
	INPUT_VALID=1
	fi

	if [ $INPUT_VALID -gt 0 ]
	then
	CIMITRA_SERVER_ADMIN_ACCOUNT="${SUGGESTION}" 
	fi
else



	if [ $INPUT_VALID -gt 0 ]
	then
	CIMITRA_SERVER_ADMIN_ACCOUNT="${INPUT}" 
	fi

fi

declare -i INPUT_LENGTH=0
CIMITRA_SERVER_ADMIN_PASSWORD="changeme"
SUGGESTION="${CIMITRA_SERVER_ADMIN_PASSWORD}"
echo -e "\033[0;93m\033[44m[PASSWORD]\033[0;93m\033[44m"
echo -e "\033[0;93m\033[44m<Enter to accept, or edit password>\033[0;93m\033[0;92m"
# read -sp "Password: " PASS_INPUT

	if [ ${OS_IS_LINUX} = 1 ]
	then
	# This method doesn't work on MacOS
unset thePassword
echo -n "Password:  "

while IFS= read -p "$prompt" -r -s -n 1 char
do
    # Enter - accept password
    if [[ $char == $'\0' ]] ; then
        break
    fi
    # Backspace
    if [[ $char == $'\177' ]] ; then
        prompt=$'\b \b'
        password="${thePassword%?}"
    else
        prompt='*'
        thePassword+="$char"
    fi
done

	INPUT_LENGTH=`echo "${thePassword}" | wc -m`

	else
	# MacOS Way of Getting Input
	
	read -p "Password: " PASS_INPUT
	thePassword="${PASS_INPUT}"
	INPUT_LENGTH=`echo "${PASS_INPUT}" | wc -m`
	fi


declare -i INPUT_VALID=1

	if [ $INPUT_LENGTH -lt 3 ]
	then
	CIMITRA_SERVER_ADMIN_PASSWORD="changeme"
	else
		if [ $INPUT_VALID -gt 0 ]
		then
		CIMITRA_SERVER_ADMIN_PASSWORD="${thePassword}"
		fi
	fi

}


if [ $CIMITRA_SERVER_ADMIN_ACCOUNT_SPECIFIED -eq 0 ]
then
PROMPT_FOR_SETTINGS
echo ""
fi

if [ $CIMITRA_AGENT_IN_SET_TEST -eq 1 ]
then
CIMITRA_AGENT_IN=`echo $@ | awk -F "name=" '{printf $2}'`
CIMITRA_AGENT_IN_SET="1"
fi

# Remove unintentional spaces from the admnin account an admin password
CIMITRA_SERVER_ADMIN_ACCOUNT="${CIMITRA_SERVER_ADMIN_ACCOUNT// /}"
CIMITRA_SERVER_ADMIN_PASSWORD="${CIMITRA_SERVER_ADMIN_PASSWORD// /}"


function CALL_ERROR_EXIT()
{
ERROR_MESSAGE="$1"
ERROR_MESSAGE="  ${ERROR_MESSAGE}  "
echo ""
if [ ${TERMINAL_TYPE} -eq 0 ]
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
if [ ${TERMINAL_TYPE} -eq 0 ]
then
echo "$(tput setaf 1)ERROR:$(tput setab 7)${ERROR_MESSAGE}$(tput sgr 0)"
else
echo "ERROR:${ERROR_MESSAGE}"
fi
echo ""
}

function CALL_COMMAND()
{
INFO_MESSAGE="$1"
INFO_MESSAGE="  ${INFO_MESSAGE}  "
echo ""
if [ ${TERMINAL_TYPE} -eq 0 ]
then
echo "$(tput setaf 7)$(tput setab 4)COMMAND:$(tput setaf 4)$(tput setab 7)${INFO_MESSAGE}$(tput sgr 0)"
else
echo "COMMAND:${INFO_MESSAGE}"
fi
echo ""
}


function CHECK_OR_INSTALL_NODEJS()
{

{
node -v 1> /dev/null 2> /dev/null
} 1> /dev/null 2> /dev/null

declare -i NODEJS_INSTALLED=`echo $?`

if [ $NODEJS_INSTALLED -eq 0 ]
then
return 0
fi

if [ $ROOT_USER -eq 1 ]
then
CALL_COMMAND "apt-get install -y nodejs"
apt-get install -y nodejs
else
CALL_COMMAND "${SUDO_COMMAND} apt-get install -y nodejs"
${SUDO_COMMAND} apt-get install -y nodejs
fi

{
node -v 1> /dev/null 2> /dev/null
} 1> /dev/null 2> /dev/null

if [ $NODEJS_INSTALLED -eq 0 ]
then
CALL_INFO "It seems like Node.js should be installed"
CALL_INFO "If this install fails, then install Node.js and try again"
fi

}

function DISCOVER_PLATFORM()
{

PLATFORM_PROCESSOR=`uname -a`

declare -i PLATFORM_PROCESSOR_ARM_TEST=`echo "${PLATFORM_PROCESSOR}" | grep -ic "arm"`

declare -i PLATFORM_PROCESSOR_INTEL_TEST=`echo "${PLATFORM_PROCESSOR}" | grep -ic "x86"`

if [ $PLATFORM_PROCESSOR_ARM_TEST -gt 0 ]
then

	if [ $PLATFORM_PROCESSOR_INTEL_TEST -lt 1 ]
	then
	ARM_PROCESSOR="1"
	fi

fi

if [ $ARM_PROCESSOR -gt 0 ]
then
CHECK_OR_INSTALL_NODEJS
fi

}

DISCOVER_PLATFORM

function CONNECT_TEST()
{

if [ $DEBUG -eq 1 ]
then
CALL_INFO "IN: $FUNCNAME"
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

CALL_INFO "Pausing for 5 Seconds to test connectivity"
sleep 5

declare -i CONNECTION_PROCESS_WORKED=`ps -eaf | grep ${CONNECTION_PROCESS} | grep -c "cat"`

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
CALL_INFO "IN: $FUNCNAME"
fi

CALL_INFO "Establishing Connection to Cimitra Server"

CALL_INFO "Server: ${CIMITRA_SERVER_ADDRESS} | Port: ${CIMITRA_SERVER_PORT}"

BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api" 

ENDPOINT="/users/login" 

URL="${BASEURL}${ENDPOINT}" 

DATA="{\"email\":\"${CIMITRA_SERVER_ADMIN_ACCOUNT}\",\"password\": \"${CIMITRA_SERVER_ADMIN_PASSWORD}\"}" 

timeout 1 bash -c "(echo > /dev/tcp/$CIMITRA_SERVER_ADDRESS/$CIMITRA_SERVER_PORT) >/dev/null 2>&1"

PORT_CHECK_EXIT_CODE=`echo $?`

if [ $PORT_CHECK_EXIT_CODE -ne 0 ]
then
CALL_ERROR "The Server and Port Are Not Available"
exit 1
fi

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
	CALL_ERROR "Cannot Authenticate to the Cimitra Server"
	exit 1
	else
	CALL_INFO "Got a Valid Connection to the Cimitra Server"
	fi

else
	if [ ${STATUS} -eq 0 ] 
	then
	CALL_ERROR "Cannot Authenticate to the Cimitra Server"
	exit 1
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
CALL_INFO "IN: $FUNCNAME"
fi

if [ $DEBUG -eq 1 ]
then

	if [ $PROCEED_WITH_AGENT_INSTALL -ne 0 ]
	then
	CALL_INFO "Agent Install Process Not Proceeding"
	else
	CALL_INFO "Agent Install Process Proceeding"
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

SERVER_HOST_NAME=`uname -n`

if [ $ARM_PROCESSOR -eq 0 ]
then
	if [ ${OS_IS_LINUX} -eq 1 ]
	then
THE_DESCRIPTION="Cimitra Agent Deployed to Host: ${SERVER_HOST_NAME}\nIf you need to install the agent again follow these 4 Simple Steps\n1. Download the Cimitra Agent and put it on the Linux box: ${AGENT_NAME} \n2. Make the cimagent file executable: chmod +x ./cimagent\n3. Install the Cimitra Agent with the command: ./cimagent c\n4. Start the Cimitra Agent with the command: cimitra start"
	else
THE_DESCRIPTION="Cimitra Agent Deployed to Host: ${SERVER_HOST_NAME}\nIf you need to install the agent again follow these 4 Simple Steps\n1. Download the Cimitra Agent and put it on the Mac Computer: ${AGENT_NAME} \n2. In a terminal session, make the cimagent file executable: chmod +x ./cimagent\n3. Install the Cimitra Agent with the command: ./cimagent c\n4. Start the Cimitra Agent with the command: cimitra start"	
	fi
else
THE_DESCRIPTION="Cimitra Agent Deployed to Host: ${SERVER_HOST_NAME}\nIf you need to install the agent again follow these 3 Simple Steps\n1. Download the Cimitra Agent and put it on the Linux box: ${AGENT_NAME} \n2. Install the Cimitra Agent with the command: node cimagent.js c\n3. Start the Cimitra Agent with the command: cimitra start"
fi



if [ ${OS_IS_LINUX} -eq 1 ]
then

	if [ $ARM_PROCESSOR -eq 0 ]
	then
	THE_PLATFORM="linux"
	else
	THE_PLATFORM="other"
	fi

else
	if [ ${OS_IS_MAC} -eq 1 ]
	then
	THE_PLATFORM="darwin"
	else
	PROCEED_WITH_AGENT_INSTALL="1"
	return 1
	fi
fi


echo "{
    \"name\": \"${AGENT_NAME}\",
    \"description\": \"${THE_DESCRIPTION}\",
    \"platform\": \"${THE_PLATFORM}\",
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

BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api"
 
ENDPOINT="/agent" 

URL="${BASEURL}${ENDPOINT}" 

# Look for all agents

if [ $DEBUG -eq 1 ]
then

CALL_INFO "A Cimitra Agent Was Just Created, Finding More Details"

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


	
declare -i CIMITRA_AGENT_NAME_EXISTS=`cat ${TEMP_FILE_TWO} | grep -icw "name:${AGENT_NAME}"`

	if [ $CIMITRA_AGENT_NAME_EXISTS -gt 0 ]
	then
	CIMITRA_PAIRED_AGENT_ID=`cat ${TEMP_FILE_TWO} | grep -iwB 1 "name:${AGENT_NAME}" | head -1 | awk -F ":" '{printf $2}'`

		if [ $DEBUG -eq 1 ]
		then
		CALL_INFO "Condition 1: An Agent By the Name of ${AGENT_NAME} Exists"
		fi

		if [ $DEBUG -eq 1 ]
		then
		CALL_INFO "Agent ID = $CIMITRA_PAIRED_AGENT_ID"
		fi
	CIMITRA_AGENT_IN_SET=1
	fi

rm ${TEMP_FILE_ONE} 2> /dev/null

rm ${TEMP_FILE_TWO} 2> /dev/null

}



function DOWNLOAD_AND_INSTALL_CIMITRA_AGENT()
{

if [ $DEBUG -eq 1 ]
then
CALL_INFO "IN: $FUNCNAME"
fi

if [ $PROCEED_WITH_AGENT_INSTALL -ne 0 ]
then
return
fi

AGENT_NAME="${CIMITRA_AGENT_IN}"

CIMITRA_AGENT_BINARY_FILE="/usr/bin/cimagent"

if [ $OS_IS_LINUX -eq 1 ]
then

	if [ $ARM_PROCESSOR -eq 0 ]
	then
	CIMITRA_AGENT_BINARY_FILE="/usr/bin/cimagent"
	else
	CIMITRA_AGENT_BINARY_FILE="/cimitra/cimagent.js"
	fi
fi

if [ $OS_IS_MAC -eq 1 ]
then
CIMITRA_AGENT_BINARY_FILE="/usr/local/bin/cimagent"
fi

test -f ${CIMITRA_AGENT_BINARY_FILE}

cimitra status 1> /dev/null 2>/dev/null

CIMITRA_COMMAND_EXISTS=`echo $?`

CIMITRA_AGENT_SCRIPT_EXISTS="0"

if [ $CIMITRA_COMMAND_EXISTS -gt 1 ]
then
CIMITRA_AGENT_SCRIPT_EXISTS="1"
fi


CIMITRA_AGENT_NOT_INSTALLED=`echo $?`

# If an agent isn't installed....

if [ $CIMITRA_AGENT_NOT_INSTALLED -eq 1 ] || [ $CIMITRA_AGENT_SCRIPT_EXISTS -eq 1 ]
then

BASEURL="https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api"
 
ENDPOINT="/agent" 

URL="${BASEURL}${ENDPOINT}" 

# Look for all agents

if [ $DEBUG -eq 1 ]
then

CALL_INFO "A Cimitra Agent is Not Installed Locally, Finding More Details"

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
	
declare -i CIMITRA_AGENT_NAME_EXISTS=`cat ${TEMP_FILE_TWO} | grep -icw "name:${AGENT_NAME}"`

	if [ $CIMITRA_AGENT_NAME_EXISTS -gt 0 ]
	then
	CIMITRA_PAIRED_AGENT_ID=`cat ${TEMP_FILE_TWO} | grep -iwB 1 "name:${AGENT_NAME}" | head -1 | awk -F ":" '{printf $2}'`

		if [ $DEBUG -eq 1 ]
		then
		CALL_INFO "Condition 2: An Agent By the Name of ${AGENT_NAME} Exists"
		fi

		if [ $DEBUG -eq 1 ]
		then
		CALL_INFO "Agent ID = $CIMITRA_PAIRED_AGENT_ID"
		fi
	else

		if [ $DEBUG -eq 1 ]
		then
		CALL_INFO "Calling Function CREATE_PAIRED_CIMITRA_AGENT"
		fi

	CREATE_PAIRED_CIMITRA_AGENT
	fi		



fi

if [ $CIMITRA_AGENT_NOT_INSTALLED -eq 0 ]
then
# echo "AGENT IS INSTALLED...Let's keep checking"
# Determine if the installed Cimitra Agent is actually still registered in Cimitra

if [ $ROOT_USER -eq 1 ]
then
	if [ $ARM_PROCESSOR -eq 0 ]
	then
	{
CIMITRA_BINARY_AGENT_ID=`${CIMITRA_AGENT_BINARY_FILE} | grep -iA1 "agentid" | tail -1 | awk -F "= " '{printf $2}'` 
	} 1> /dev/null 2> /dev/null
	else
	{
CIMITRA_BINARY_AGENT_ID=`node ${CIMITRA_AGENT_BINARY_FILE} | grep -iA1 "agentid" | tail -1 | awk -F "= " '{printf $2}'` 
	} 1> /dev/null 2> /dev/null
	fi
else
	if [ $ARM_PROCESSOR -eq 0 ]
	then
CIMITRA_BINARY_AGENT_ID=`${SUDO_COMMAND} ${CIMITRA_AGENT_BINARY_FILE} | grep -iA1 "agentid" | tail -1 | awk -F "= " '{printf $2}'`
	else
CIMITRA_BINARY_AGENT_ID=`${SUDO_COMMAND} node ${CIMITRA_AGENT_BINARY_FILE} | grep -iA1 "agentid" | tail -1 | awk -F "= " '{printf $2}'`
	fi
fi
if [ $DEBUG -eq 1 ]
then
CALL_INFO "Agent ID = ${CIMITRA_BINARY_AGENT_ID}"
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
CALL_INFO "Cimitra Agent Exists = $CIMITRA_AGENT_ID_EXISTS"
fi

	if [ $CIMITRA_AGENT_ID_EXISTS -gt 0 ]
	then
	CIMITRA_PAIRED_AGENT_ID=`cat ${TEMP_FILE_TWO} | grep -iw  "_id:${SEARCH_FOR}" | head -1 | awk -F ":" '{printf $2}'`
	CIMITRA_PAIRED_AGENT_NAME=`cat ${TEMP_FILE_TWO} | grep -A 1 ${SEARCH_FOR} | tail -1 | awk -F ":" '{printf $2}'`
	CIMITRA_PAIRED_AGENT_NAME_LOWER=`echo "${CIMITRA_PAIRED_AGENT_NAME}" | tr [A-Z] [a-z]`
	

		if [ $DEBUG -eq 1 ]
		then
		CALL_INFO "Cimitra Agent ID:   ${CIMITRA_PAIRED_AGENT_ID}"
		CALL_INFO "Cimitra Agent Name: ${CIMITRA_PAIRED_AGENT_NAME}"
		fi

	rm ${TEMP_FILE_ONE} 2> /dev/null
	rm ${TEMP_FILE_TWO} 2> /dev/null
	CALL_INFO "The Cimitra Agent is Already Installed"

	return 0

		
	else



		AGENT_NAME="${CIMITRA_AGENT_IN}"

		if [ $DEBUG -eq 1 ]
		then
		CALL_INFO "Agent Name: ${AGENT_NAME}"
		fi


	declare -i CIMITRA_AGENT_NAME_EXISTS=`cat ${TEMP_FILE_TWO} | grep -icw "name:${AGENT_NAME}"`


		if [ $CIMITRA_AGENT_NAME_EXISTS -gt 0 ]
		then
		CALL_INFO "The Cimitra Agent is already installed"
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

	if [ $ARM_PROCESSOR -eq 0 ]
	then
CIMAGENT_FILE="${TEMP_FILE_DIRECTORY}/cimagent"
	else
CIMAGENT_FILE="${TEMP_FILE_DIRECTORY}/cimagent.js"
	fi



if [ $DEBUG -eq 1 ]
then

	if [ $ROOT_USER -eq 1 ]
	then
	rm ${CIMAGENT_FILE} 2> /dev/null
	else
	${SUDO_COMMAND} rm ${CIMAGENT_FILE} 
	fi
else
	if [ $ROOT_USER -eq 1 ]
	then
	rm ${CIMAGENT_FILE} 2> /dev/null
	else
	${SUDO_COMMAND} rm ${CIMAGENT_FILE}
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

test -f ${CIMAGENT_FILE}

declare -i CIMAGENT_FILE_EXISTS=`echo $?`

if [ $CIMAGENT_FILE_EXISTS -ne 0 ]
then
echo ""
CALL_ERROR "Could not Download the Cimitra Agent File"
return
fi

AGENT_INSTALL_PROCESS_SUCCESS="1"

# CALL_COMMAND "sudo chmod +x ${CIMAGENT_FILE}"

	if [ $ROOT_USER -eq 1 ]
	then
		if [ $ARM_PROCESSOR -eq 0 ]
		then
	chmod +x ${CIMAGENT_FILE}
		fi
	else
		if [ $ARM_PROCESSOR -eq 0 ]
		then
	${SUDO_COMMAND} chmod +x ${CIMAGENT_FILE}
		fi
	fi



# CALL_COMMAND "cd ${TEMP_FILE_DIRECTORY}"

cd ${TEMP_FILE_DIRECTORY}

if [ $DEBUG -eq 1 ]
then

	if [ $ROOT_USER -eq 1 ]
	then
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		./cimagent
		else
		node ./cimagent.js
		fi
	else
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		${SUDO_COMMAND} ./cimagent
		else
		${SUDO_COMMAND} node ./cimagent.js
		fi
	fi


else

	if [ $ROOT_USER -eq 1 ]
	then
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		./cimagent 1> /dev/null 2> /dev/null
		else
		node ./cimagent.js 1> /dev/null 2> /dev/null
		fi
	else
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		${SUDO_COMMAND} ./cimagent 
		else
		${SUDO_COMMAND} node ./cimagent.js 
		fi
	fi
fi

DOWNLOAD_FILE_STATE=`echo $?`

if [ $DOWNLOAD_FILE_STATE -ne 0 ]
then
AGENT_INSTALL_PROCESS_SUCCESS="0"
	if [ $ROOT_USER -eq 1 ]
	then
	rm ${CIMAGENT_FILE} 2> /dev/null
	else
	${SUDO_COMMAND} rm ${CIMAGENT_FILE}
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

	if [ $ROOT_USER -eq 1 ]
	then
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		chmod +x ${CIMAGENT_FILE}
		fi
	else
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		${SUDO_COMMAND} chmod +x ${CIMAGENT_FILE}
		fi
	fi



if [ $DEBUG -eq 1 ]
then

	if [ $ROOT_USER -eq 1 ]
	then
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		./cimagent
		else
		node ./cimagent.js
		fi
	else
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		${SUDO_COMMAND} ./cimagent
		else
		${SUDO_COMMAND} node ./cimagent.js
		fi
	fi



else
	if [ $ROOT_USER -eq 1 ]
	then
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		./cimagent 1> /dev/null 2> /dev/null 
		else
		node ./cimagent.js 1> /dev/null 2> /dev/null 
		fi
	else
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		${SUDO_COMMAND} ./cimagent
		else
		${SUDO_COMMAND} node ./cimagent.js	
		fi
	fi
fi

DOWNLOAD_FILE_STATE=`echo $?`

if [ $DOWNLOAD_FILE_STATE -eq 0 ]
then

AGENT_INSTALL_PROCESS_SUCCESS="1"

CALL_INFO "Running Agent Install Routine"

if [ $SYSTEMD_INSTALL -eq 0 ]
then

{
cimitra status 1> /dev/null 2> /dev/null
} 1> /dev/null 2> /dev/null

declare -i CIMITRA_STATUS=`echo $?`

	if [ $CIMITRA_STATUS -eq 0 ]
	then
		if [ $ROOT_USER -eq 1 ]
		then
		CALL_COMMAND "cimitra stop"
		cimitra stop
		else
		CALL_COMMAND "${SUDO_COMMAND} cimitra stop"
		${SUDO_COMMAND} cimitra stop
		fi

		CALL_COMMAND "sleep 5"

		sleep 5
	fi





	if [ $ROOT_USER -eq 1 ]
	then
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		CALL_COMMAND "./cimagent c"
		./cimagent c
		else
		CALL_COMMAND "node ./cimagent.js c"
		node ./cimagent.js c
		fi
	else
		if [ $ARM_PROCESSOR -eq 0 ]
		then
		CALL_COMMAND "${SUDO_COMMAND} ./cimagent c"
		${SUDO_COMMAND} ./cimagent c
		else
		CALL_COMMAND "${SUDO_COMMAND} node ./cimagent.js c"
		${SUDO_COMMAND} node ./cimagent.js c		
		fi
	fi



else

	if [ $CIMITRA_STATUS -eq 0 ]
	then

		if [ $ROOT_USER -eq 1 ]
		then
		CALL_COMMAND "cimitra stop"
		cimitra stop
		else
		CALL_COMMAND "${SUDO_COMMAND} cimitra stop"
		${SUDO_COMMAND} cimitra stop
		fi
		
		CALL_COMMAND "sleep 5"

		sleep 5
		
	fi




	if [ ${OS_IS_LINUX} = 1 ]
	then

		if [ $ROOT_USER -eq 1 ]
		then
			if [ $ARM_PROCESSOR -eq 0 ]
			then
			CALL_COMMAND "./cimagent c systemd"
			./cimagent c systemd
			else
			CALL_COMMAND "node ./cimagent.js c systemd"
			node ./cimagent.js c systemd	
			fi
		else
			if [ $ARM_PROCESSOR -eq 0 ]
			then
			CALL_COMMAND "${SUDO_COMMAND} ./cimagent c systemd"
			${SUDO_COMMAND} ./cimagent c systemd
			else
			CALL_COMMAND "${SUDO_COMMAND} node ./cimagent.js c systemd"
			${SUDO_COMMAND} node ./cimagent.js c systemd		
			fi

		fi
	fi

	if [ ${OS_IS_MAC} = 1 ]
	then
		if [ $ROOT_USER -eq 1 ]
		then
		CALL_COMMAND "./cimagent c"
		./cimagent c systemd
		else
		CALL_COMMAND "${SUDO_COMMAND} ./cimagent c"
		${SUDO_COMMAND} ./cimagent c systemd
		fi

	fi
	
fi


		if [ $ROOT_USER -eq 1 ]
		then
		{
		cimitra stop 2> /dev/null 
		CALL_COMMAND "sleep 5"

		sleep 5
		cimitra start  &
		} 1> /dev/null 2> /dev/null
		else
		{
		${SUDO_COMMAND} cimitra stop 

		CALL_COMMAND "sleep 5"

		sleep 5
		${SUDO_COMMAND} cimitra start &
		} 1> /dev/null 2> /dev/null
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
CALL_INFO "IN: $FUNCNAME"
fi


		if [ $ROOT_USER -eq 1 ]
		then
		cimitra get modules
		cimitra get import 
		cimitra get agent
		cimitra agent checkup install
		else
		${SUDO_COMMAND} cimitra get modules
		${SUDO_COMMAND} cimitra get import
		${SUDO_COMMAND} cimitra get agent
		${SUDO_COMMAND} cimitra agent checkup install
		fi
}


function main()
{
if [ $DEBUG -eq 1 ]
then
CALL_INFO "IN: $FUNCNAME"
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
		cimitra stop 1> /dev/null 2> /dev/null &
		} 1> /dev/null 2> /dev/null 
		else
		CALL_COMMAND "${SUDO_COMMAND} cimitra stop"
		${SUDO_COMMAND} cimitra stop
		fi

		if [ $ROOT_USER -eq 1 ]
		then
		CALL_COMMAND "cimitra start"
		{
		cimitra start & 1> /dev/null 2> /dev/null &
		} 1> /dev/null 2> /dev/null 

		else
		CALL_COMMAND "${SUDO_COMMAND} cimitra start"

		{
		${SUDO_COMMAND} cimitra start & 1> /dev/null 2> /dev/null &
		} 1> /dev/null 2> /dev/null 

		fi

DOWNLOAD_CIMITRA_APIS



if [ $AGENT_INSTALL_PROCESS_SUCCESS -eq 1 ]
then

	if [ $ROOT_USER -eq 1 ]
	then
	CALL_COMMAND "cimitra status"
	cimitra status
	else
	CALL_COMMAND "${SUDO_COMMAND} cimitra status"
	${SUDO_COMMAND} cimitra status
	fi

	cd /var/opt/cimitra/api/import

	if [ $OS_IS_MAC -eq 0 ]
	then
	./import -b -u ${CIMITRA_SERVER_ADMIN_ACCOUNT} -p ${CIMITRA_SERVER_ADMIN_PASSWORD} name="HOST INFO"^ command=echo '[ Command: uname -n ]' ";" uname -n ";" echo ";" echo '[ Command: uname -a ]' ";" uname -a ";" echo ";" echo '[ Command: ip address show ]' ";" ip address show ";" echo '[ Command: lscpu ]' ";" echo ";" lscpu ";" echo '[ Command: lsblk ]' ";" echo ";" lsblk ";" echo '[ Command: df -hl ]' ";" echo ";" df -hl ";" echo '[ Command: top -bn1 ]' ";" echo ";" top -bn1^
		if [ $BACKUP_INSTALL -gt 0 ]
		then
    ./import -b -u ${CIMITRA_SERVER_ADMIN_ACCOUNT} -p ${CIMITRA_SERVER_ADMIN_PASSWORD} name="BACKUP CIMITRA SERVER"^ command=cimitra server backup^
		fi
	else
	./import -b -u ${CIMITRA_SERVER_ADMIN_ACCOUNT} -p ${CIMITRA_SERVER_ADMIN_PASSWORD} name="HOST INFO"^ command=echo '[ Command: uname -n ]' ";" uname -n ";" echo ";" echo '[ Command: uname -a ]' ";" uname -a ";" echo ";" echo '[ Command: sysctl -n machdep.cpu.brand_string ]' ";" sysctl -n machdep.cpu.brand_string ";" echo ";" echo '[ Command: ifconfig ]' ";" ifconfig ";" echo '[ Command: sw_vers ]' ";" echo ";" sw_vers ";"  echo '[ Command: df -hl ]' ";" echo ";" df -hl^
	fi
	./import -b -u ${CIMITRA_SERVER_ADMIN_ACCOUNT} -p ${CIMITRA_SERVER_ADMIN_PASSWORD} name="PING"^ command=echo ";" ping ^  inputone=-c 2@ADDRESS@ADDRESS@false^
	
	if [ $OS_IS_MAC -eq 1 ]
	then
	cd /var/opt/cimitra/api 2> /dev/null
	rm /var/opt/cimitra/api/import/* 2> /dev/null
	rmdir /var/opt/cimitra/api/import 2> /dev/null
	fi
	
fi

CHECKMARK_MESSAGE "Cimitra Agent Deployed"

else
CALL_INFO "Cimitra Agent Not Downloaded, It is Already Installed"
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

rm -rv ./modules 2> /dev/null
rm -rv ./import 2> /dev/null
rm -rv ./agent 2> /dev/null

}

function REMOVE_CIMITRA_AGENT()
{

CIMITRA_AGENT_BIN_FILE="/usr/bin/cimagent"

if [ $OS_IS_LINUX -eq 1 ]
then
CIMITRA_AGENT_BIN_FILE="/usr/bin/cimagent"
fi

if [ $OS_IS_MAC -eq 1 ]
then
CIMITRA_AGENT_BIN_FILE="/usr/local/bin/cimagent"
fi

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



CALL_INFO "[ Cimitra Agent Install Script - Finish ]"
