# Cimitra Windows Agent Deployment Script
# Version 1.0
# Release Date: 9/1/2020
# Author: Tay Kratzer tay@cimitra.com
# ---------------------------------------

$TEMP_FILE=New-TemporaryFile
$GLOBAL_TEMP_FILE_TWO=New-TemporaryFile
$global:cimitraCfgFound = $false
$global:cimitraExeFound = $false
$global:cimitraServiceFound = $true
$global:cimitraAgentId = "Undefined"
$global:cimitraAgentIdFound = $true
$global:cimitraAgentFoundInCimitraServer = $false
$global:CIMITRA_SERVER_ADDRESS = $args[0]
$global:CIMITRA_SERVER_PORT = $args[1]
$global:CIMITRA_SERVER_ADMIN_ACCOUNT = $args[2]
$global:CIMITRA_SERVER_ADMIN_PASSWORD = $args[3]
$global:CIMITRA_AGENT_CONFIG_FILE_PATH = "c:\cimitra\cimitra.cfg"
$global:CIMITRA_AGENT_EXE_FILE_PATH = "c:\cimitra\cimagent.exe"
$global:CIMITRA_EXE_BASE_PATH = "c:\cimitra"
$cimitraAgentNameBase = ($env:computername).ToUpper()
$global:cimitraAgentName = $cimitraAgentNameBase 
$global:IMPORT_FOLDER_ID = ""
$global:CIMITRA_AGENT_IMPORT_FOLDER_ID = ""
$global:removeCimitraAgentAndConfig = $false
$global:cimitraAgentNameFound = $false


$script:CIMITRA_AGENT_IMPORT_FOLDER="$agentImportFolderId"

if(test-path $CIMITRA_AGENT_CONFIG_FILE_PATH){
$global:cimitraCfgFound = $true
}

if(test-path $CIMITRA_AGENT_EXE_FILE_PATH){
$global:cimitraExeFound = $true
}

$ARG_THREE = $args[2]
$ARG_FIVE = $args[4]



if (($ARG_THREE | Select-String -CaseSensitive "\bname=\b" )){

$cimitraAgentNameOne = ( $ARG_THREE | %{ $_.Split('=')[1];} )

$cimitraAgentNameTwo = $cimitraAgentNameOne -replace " ", ""

$global:cimitraAgentName = $cimitraAgentNameTwo

$global:CIMITRA_SERVER_ADMIN_ACCOUNT = ""

$global:CIMITRA_SERVER_ADMIN_PASSWORD = ""

}else{


    if (($ARG_FIVE | Select-String -CaseSensitive "\bname=\b" )){

    $cimitraAgentNameOne = ( $ARG_FIVE | %{ $_.Split('=')[1];} )

    $cimitraAgentNameTwo = $cimitraAgentNameOne -replace " ", ""
    
    $global:cimitraAgentName = $cimitraAgentNameTwo

    }


}


if (($ARG_THREE | Select-String -CaseSensitive "\breinstall\b" )){

    $global:removeCimitraAgentAndConfig = $true

}else{


    if (($ARG_FIVE | Select-String -CaseSensitive "\breinstall\b" )){

        $global:removeCimitraAgentAndConfig = $true

    }


}


# Show Help
function ShowHelp{
$scriptName = Split-Path -leaf $PSCommandpath
Write-Host ""
Write-Host "--- Script Help ---"
Write-Host ""
Write-Host "Install Cimitra Agent on Windows (No prompt for credentials method)"
Write-Host ""
Write-Host ".\$scriptName <cimitra server address> <cimitra server port> <cimitra server admin user> <cimitra admin user password>"
Write-Host ""
Write-Host "Example:"
Write-Host ""
Write-Host ".\$scriptName 192.168.1.10 443 admin@cimitra.com myPassword"
Write-Host ""
Write-Host "Install Cimitra Agent on Windows  (Prompt for credentials method)"
Write-Host ""
Write-Host ".\$scriptName <cimitra server address> <cimitra server port>"
Write-Host ""
Write-Host "Example:"
Write-Host ""
Write-Host ".\$scriptName 192.168.1.10 443"
Write-Host ""
Write-Host "Specify Agent Name"
Write-Host ""
Write-Host "Specify Agent Name (No prompt for credentials method)"
Write-Host ""
Write-Host ".\$scriptName <cimitra server address> <cimitra server port> <cimitra server admin user> <cimitra admin user password> name=<agentName>"
Write-Host ""
Write-Host "Example:"
Write-Host ""
Write-Host ".\$scriptName 192.168.1.10 443 admin@cimitra.com myPassword name=MyFavoriteWindowsBox"
Write-Host ""
Write-Host "Specify Agent Name  (Prompt for credentials method)"
Write-Host ""
Write-Host ".\$scriptName <cimitra server address> <cimitra server port> name=<agentName>"
Write-Host ""
Write-Host "Example:"
Write-Host ""
Write-Host ".\$scriptName 192.168.1.10 443 name=MyFavoriteWindowsBox"
Write-Host ""
Write-Host ""
Write-Host "Reinstall Cimitra Agent"
Write-Host ""
Write-Host ".\$scriptName <cimitra server address> <cimitra server port> <cimitra server admin user> <cimitra admin user password> reinstall"
Write-Host ""
Write-Host "Example:"
Write-Host ""
Write-Host ".\$scriptName 192.168.1.10 443 admin@cimitra.com myPassword reinstall"
Write-Host ""
Write-Host "Script Help"
Write-Host ""
Write-Host ".\$scriptName -h or -help"
Write-Host ""
Write-Output "-------------------"
Write-Output ""
Write-Output "Most Common Usage"
Write-Host ""
Write-Host ".\$scriptName 192.168.1.10 443 admin@cimitra.com myPassword"
Write-Host ""
Write-Output "-------------------"
Write-Output ""
exit 0
}

Write-Output ""
Write-Host "START - CIMITRA WINDOWS AGENT COMMAND LINE INSTALL SCRIPT" -ForegroundColor Green
Write-Output "---------------------------------------------------------"


function CHECK_ADMIN_LEVEL{

Write-Output ""
Write-Host "Checking for elevated permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Output ""
Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
exit 1
}
else {
Write-Output ""
Write-Host "PROCEEDING: Running as Administrator" -ForegroundColor Green
}

}

CHECK_ADMIN_LEVEL

if (Write-Output $args | Select-String "\-h\b|\-help\b" )
{
ShowHelp
}


if ($CIMITRA_SERVER_ADDRESS.length -eq 0){
ShowHelp
}


if ($CIMITRA_SERVER_PORT.length -eq 0){
ShowHelp
}


$CONFIG_FILE_DEFAULT="c:\cimitra\cimitra.cfg"

$CONFIG_FILE_IN = $CONFIG_FILE_DEFAULT



function ConfirmFromConfigFile{
# USAGE: ConfirmFromConfigFile <config file> <variable name> <variable value> 
# EXAMPLE: ConfirmFromConfigFile 'c:\cimitra\scripts\settings.cfg' 'SERVER_ADDRESS'

# Read in 2 parameters
$CONFIG_FILE_IN=$args[0]
$VARIABLE_NAME=$args[1]

# Create the file if it doesn't exist
if (!(Test-Path $CONFIG_FILE_IN))
{
return $false
}
# ----------------------------------------------------------------------- #
# If the value exists, take everything out of the file . . 
# ...except the matching string and copy it to the temporary file
# If the value doesn't exist, copy the entire config file to the temp file
# ----------------------------------------------------------------------- #

$CONFIG_FILE_CONTENTS = Get-Content "$CONFIG_FILE_IN"

if ( $CONFIG_FILE_CONTENTS -match "${VARIABLE_NAME}" ){
return $true
}else{
return $false
}

}


function ReadFromConfigFile{
# USAGE: $<YOUR NAME FOR THE CONFIG FILE>=(ReadFromConfigFile '<config file to read>')
# EXAMPLE: $CONFIG=(ReadFromConfigFile 'c:\temp\test.txt')
$CONFIG_FILE_IN=$args[0]

$TEMP_FILE_ONE=New-TemporaryFile

cat $CONFIG_FILE_IN 1> $TEMP_FILE_ONE

Get-Content $TEMP_FILE_ONE | Where-Object {$_.length -gt 0} | Where-Object {!$_.StartsWith("#")} | ForEach-Object {

    $var = $_.Split('=',2).Trim()
    Write-Output "VAR1 = $var"
    # $var = [regex]::match($var1, '[\d\.]+').Value
    New-Variable -Scope Script -Name $var[0] -Value $var[1]
    }

Remove-Item -Path $TEMP_FILE_ONE -Force

}

function WriteToConfigFile{
# USAGE: WriteToConfigFile <config file> <variable name> <variable value> 
# EXAMPLE: WriteToConfigFile 'c:\cimitra\scripts\settings_ad.cfg' 'SERVER_ADDRESS' '192.168.1.1'

# Read in 3 parameters
$CONFIG_FILE_IN=$args[0]
$VARIABLE_NAME=$args[1]
$VARIABLE_VALUE=$args[2]
$TEMP_FILE_ONE=New-TemporaryFile

# Create the file if it doesn't exist
if (!(Test-Path $CONFIG_FILE_IN))
{
New-Item $CONFIG_FILE_IN
}
# ----------------------------------------------------------------------- #
# If the value exists, take everything out of the file . . 
# ...except the matching string and copy it to the temporary file
# If the value doesn't exist, copy the entire config file to the temp file
# ----------------------------------------------------------------------- #
if ((Get-Content "$CONFIG_FILE_IN") -match "$VARIABLE_NAME"){
(Get-Content "$CONFIG_FILE_IN") -notmatch "$VARIABLE_NAME" | Out-File "$TEMP_FILE_ONE"
}else{
Copy-Item "$CONFIG_FILE_IN" -Destination "$TEMP_FILE_ONE"
}

# Add the Variable and Value to the temp file
Add-Content $TEMP_FILE_ONE -Value "$VARIABLE_NAME=$VARIABLE_VALUE"

# Copy the temp file over the top of the config file
Copy-Item "$TEMP_FILE_ONE" -Destination "$CONFIG_FILE_IN"

# Remove the temporary file
if ((Test-Path $TEMP_FILE_ONE))
{
Remove-Item -Path $TEMP_FILE_ONE -Force
}
# cat $CONFIG_FILE_IN
}

function confirmConfigSetting{

$CONFIG_FILE_IN=$args[0]
$VARIABLE_NAME=$args[1]
$VARIABLE_VALUE=$args[2]

if (!(ConfirmFromConfigFile "$CONFIG_FILE_IN" "$VARIABLE_NAME")){

WriteToConfigFile "$CONFIG_FILE_IN" "$VARIABLE_NAME" "$VARIABLE_VALUE"

}

}


function CALL_ERROR_EXIT{
$ErrorMessageIn=$args[0]
Write-Output ""
Write-Host "ERROR: $ErrorMessageIn" -ForegroundColor red -BackgroundColor white
Write-Output ""
exit 1
}

function CREATE_CIMITRA_APPS{

write-output ""
write-output "START: ADD CIMITRA AGENT CREATION IMPORT APPS"
write-output "---------------------------------------------"

ESTABLISH_CIMITRA_API_SESSION

DISCOVER_AGENT_DETAILS

CREATE_IMPORT_FOLDER_STRUCTURE

$CIMITRA_EXE_BASE_PATH = Split-Path -Path $CIMITRA_AGENT_EXE_FILE_PATH

$global:CIMITRA_EXE_BASE_PATH = $CIMITRA_EXE_BASE_PATH

$CIMITRA_SCRIPT_BASE_PATH = "${CIMITRA_EXE_BASE_PATH}\scripts"

POWERSHELL_SCRIPT_EXCUTION_RIGHTS "$CIMITRA_SCRIPT_BASE_PATH"

New-Item -ItemType "directory" -Path "$CIMITRA_SCRIPT_BASE_PATH" -Force 2>&1 | out-null

$scriptRoot = Write-Output "${CIMITRA_SCRIPT_BASE_PATH}" | % {$_ -replace '\\','\\'}

$INSTALLATION_DIRECTORY = "${CIMITRA_SCRIPT_BASE_PATH}"

write-output ""

if(!(Test-Path ${CIMITRA_SCRIPT_BASE_PATH}\RestartPrinter.ps1)){

$CIMITRA_DOWNLOAD = "https://raw.githubusercontent.com/cimitrasoftware/powershell_scripts/master/RestartPrinter.ps1"

$CIMITRA_DOWNLOAD_OUT_FILE = "${CIMITRA_SCRIPT_BASE_PATH}\RestartPrinter.ps1"
Write-Output ""
write-output "Download From GitHub Cimitra Script: RestartPrinter.ps1"
Write-Output ""
Invoke-WebRequest $CIMITRA_DOWNLOAD -OutFile $CIMITRA_DOWNLOAD_OUT_FILE -UseBasicParsing
}

if(!(Test-Path ${CIMITRA_SCRIPT_BASE_PATH}\ListServerDrivesFreespace.ps1)){

$CIMITRA_DOWNLOAD = "https://raw.githubusercontent.com/cimitrasoftware/powershell_scripts/master/ListServerDrivesFreespace.ps1"
$CIMITRA_DOWNLOAD_OUT_FILE = "${CIMITRA_SCRIPT_BASE_PATH}\ListServerDrivesFreespace.ps1"

Write-Output ""
write-output "Download From GitHub Cimitra Script: ListServerDrivesFreespace.ps1"
Write-Output ""

Invoke-WebRequest $CIMITRA_DOWNLOAD -OutFile $CIMITRA_DOWNLOAD_OUT_FILE -UseBasicParsing

}

if(!(Test-Path ${CIMITRA_SCRIPT_BASE_PATH}\ListService.ps1)){


$CIMITRA_DOWNLOAD = "https://raw.githubusercontent.com/cimitrasoftware/powershell_scripts/master/ListService.ps1"
$CIMITRA_DOWNLOAD_OUT_FILE = "${CIMITRA_SCRIPT_BASE_PATH}\ListService.ps1"

Write-Output ""
write-output "Download From GitHub Cimitra Script: ListService.ps1"
Write-Output ""

Invoke-WebRequest $CIMITRA_DOWNLOAD -OutFile $CIMITRA_DOWNLOAD_OUT_FILE -UseBasicParsing

}


# No Input App
$jsonFile = "{`"type`":1,`"status`":`"active`",`"platform`":`"win32`",`"interpreter`":`"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe`",`"command`":`"${scriptRoot}\\RestartPrinter.ps1`",`"params`":`"`",`"agentId`":`"${cimitraAgentId}`",`"name`":`"RESTART PRINT SERVICE`",`"notes`":`" `",`"description`":`"Restart the Print Service on Windows Computer: $cimitraAgentNameBase`",`"parentFolderId`":`"${CIMITRA_AGENT_IMPORT_FOLDER_ID}`"}"
CREATE_CIMITRA_APP "RESTART PRINT SERVICE" "RestartPrinter.ps1" "${CIMITRA_AGENT_IMPORT_FOLDER_ID}" "${IMPORT_FOLDER_ID}" "$jsonFile"
# No Input App
$jsonFile = "{`"type`":1,`"status`":`"active`",`"platform`":`"win32`",`"interpreter`":`"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe`",`"command`":`"${scriptRoot}\\ListServerDrivesFreespace.ps1`",`"params`":`"`",`"agentId`":`"${cimitraAgentId}`",`"name`":`"REPORT DISK SPACE`",`"notes`":`" `",`"description`":`"Report Disk Space on Windows Computer: $cimitraAgentNameBase`",`"parentFolderId`":`"${CIMITRA_AGENT_IMPORT_FOLDER_ID}`"}"
CREATE_CIMITRA_APP "REPORT DISK SPACE" "ListServerDrivesFreespace.ps1" "${CIMITRA_AGENT_IMPORT_FOLDER_ID}" "${IMPORT_FOLDER_ID}" "$jsonFile"

# One Input App
$jsonFile = "{`"type`":1,`"status`":`"active`",`"platform`":`"win32`",`"injectParams`":[{`"param`":`" `",`"value`":`"`",`"label`":`"Service Name`",`"regex`":`"/^[0-9A-Za-z_+-=]+`$/`",`"placeholder`":`"wscsvc`"}],`"interpreter`":`"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe`",`"command`":`"${scriptRoot}\\ListService.ps1`",`"params`":`"`",`"agentId`":`"${cimitraAgentId}`",`"name`":`"WINDOWS SERVICE INFO`",`"notes`":`"NOTE - You can use wildcards, for example: cim*`",`"description`":`"List the details of a Windows Service on Windows Computer: $cimitraAgentNameBase`",`"parentFolderId`":`"${CIMITRA_AGENT_IMPORT_FOLDER_ID}`"}"
CREATE_CIMITRA_APP "WINDOWS SERVICE INFO" "ListService.ps1" "${CIMITRA_AGENT_IMPORT_FOLDER_ID}" "${IMPORT_FOLDER_ID}" "$jsonFile"


write-output "------------------------------------------------"
write-output "FINISH: ADD CIMITRA AGENT CREATION IMPORT APPS"
write-output ""

}




function PROMPT_FOR_CIMITRA_SERVER_CONNECTIVITY{

write-output ""
write-output "START: DEFINE CIMITRA SERVER CONNECTIVITY"
write-output "-----------------------------------------"

Write-Output ""
$cimitraServerAddress = Read-Host -Prompt "Cimitra Server Address" 

$script:CIMITRA_SERVER_ADDRESS="$cimitraServerAddress"
Write-Output ""
Write-Host "Server Address: $CIMITRA_SERVER_ADDRESS" -ForegroundColor blue -BackgroundColor white

Write-Output ""
$cimitraServerPort = Read-Host -Prompt "Cimitra Server Port" 
Write-Output ""
$script:CIMITRA_SERVER_PORT="$cimitraServerPort"
Write-Host "Server Port: $CIMITRA_SERVER_PORT" -ForegroundColor blue -BackgroundColor white

Write-Output ""
$Admin = Read-Host -Prompt "Cimitra Server Admin Account: " 

$script:CIMITRA_SERVER_ADMIN_ACCOUNT="$Admin"

Write-Host "Admin Account: $Admin" -ForegroundColor blue -BackgroundColor white

Write-Output ""
$Pass = Read-Host -AsSecureString -Prompt "Cimitra Server Admin Password" 

$plainPwdIn =[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass))

$script:CIMITRA_SERVER_ADMIN_PASSWORD="$plainPwdIn"

Write-Host "Admin Password Set" -ForegroundColor blue -BackgroundColor white

write-output ""
write-output "------------------------------------------"
write-output "FINISH: DEFINE CIMITRA SERVER CONNECTIVITY"
write-output ""

}




function PROMPT_FOR_CIMITRA_SERVER_CREDENTIALS{

write-output ""
write-output "START: DEFINE CIMITRA SERVER CREDENTIALS"
write-output "----------------------------------------"

Write-Output ""
$Admin = Read-Host -Prompt "Cimitra Server Admin Account - EXAMPLE: admin@cimitra.com" 

if ($Admin.length -lt 5){
Write-Output ""
Write-Host "Error: Account Not Specified" -ForegroundColor red -BackgroundColor white
Write-Output ""
exit 1
}

$script:CIMITRA_SERVER_ADMIN_ACCOUNT="$Admin"

Write-Output ""
Write-Host "Admin Account: $Admin" -ForegroundColor blue -BackgroundColor white
Write-Output ""
$Pass = Read-Host -AsSecureString -Prompt "Cimitra Server Admin Password" 

if ($Pass.length -lt 2){
Write-Output ""
Write-Host "Error: Password Not Specified" -ForegroundColor red -BackgroundColor white
Write-Output ""
exit 1
}

$plainPwdIn =[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass))

$script:CIMITRA_SERVER_ADMIN_PASSWORD="$plainPwdIn"

Write-Output ""
Write-Host "Admin Password Set" -ForegroundColor blue -BackgroundColor white

write-output ""
write-output "-----------------------------------------"
write-output "FINISH: DEFINE CIMITRA SERVER CREDENTIALS"
write-output ""

}

if ($CIMITRA_SERVER_ADDRESS.length -eq 0){
PROMPT_FOR_CIMITRA_SERVER_CONNECTIVITY
}


if ($CIMITRA_SERVER_PORT.length -eq 0){
PROMPT_FOR_CIMITRA_SERVER_CONNECTIVITY
}


if ($CIMITRA_SERVER_ADMIN_ACCOUNT.length -eq 0){
PROMPT_FOR_CIMITRA_SERVER_CREDENTIALS
}


if ($CIMITRA_SERVER_ADMIN_PASSWORD.length -eq 0){
PROMPT_FOR_CIMITRA_SERVER_CREDENTIALS
}


function CHECK_FOR_CIMITRA_SERVICE{

try{
Get-Service Cimitra | Out-Null
}catch{
$global:cimitraServiceFound = $false
}

}

CHECK_FOR_CIMITRA_SERVICE


function CREATE_CIMITRA_FOLDER_ENTITY{

$FolderNameIn=$args[0]
$FolderDescriptionIn=$args[1]
$ParentFolderIdIn=$args[2]

$URL = "$uri/apps"

$response = Invoke-WebRequest -Uri "${URL}" `
-Method "POST" `
-Headers @{
"Authorization"="Bearer $token"
} `
-ContentType "application/json" `
-Body "{`"type`":2,`"status`":`"active`",`"description`":`"${FolderDescriptionIn}`",`"name`":`"${FolderNameIn}`",`"parentFolderId`":`"${ParentFolderIdIn}`"}"

}

function CHECK_FOR_EXISTING_APP{

$ParentFolderIdIn=$args[0]
$ExcludeFolderIdIn=$args[1]
$AppScriptIn=$args[2]

$TEMP_FILE_ONE=New-TemporaryFile
$TEMP_FILE_TWO=New-TemporaryFile

Invoke-RestMethod -Uri $uri/apps/$ParentFolderIdIn/children -Method GET -Headers $headers -UseBasicParsing > $TEMP_FILE_ONE

if ((Get-Content "$TEMP_FILE_ONE" | Select-String -CaseSensitive "\b${AppScriptIn}\b" )){
Remove-Item -Path $TEMP_FILE_ONE -Force 2>&1 | out-null
return $true
}else{
Remove-Item -Path $TEMP_FILE_ONE -Force 2>&1 | out-null

    Invoke-RestMethod -Uri $uri/apps/$ExcludeFolderIdIn/children -Method GET -Headers $headers -UseBasicParsing > $TEMP_FILE_TWO

    if ((Get-Content "$TEMP_FILE_TWO" | Select-String -CaseSensitive "\b${AppScriptIn}\b" )){
    Remove-Item -Path $TEMP_FILE_TWO -Force 2>&1 | out-null
    return $true
    }else{
    Remove-Item -Path $TEMP_FILE_TWO -Force 2>&1 | out-null
    return $false
    }

}


}


function CREATE_CIMITRA_APP{

$AppNameIn=$args[0]
$AppScriptIn=$args[1]
$ParentFolderIdIn=$args[2]
$ExcludeFolderIdIn=$args[3]
$jsonFileIn=$args[4]


if ( CHECK_FOR_EXISTING_APP "${ParentFolderIdIn}" "${ExcludeFolderIdIn}" "${AppScriptIn}" ){
return
}else{
Write-Output ""
Write-Output "Creating Cimitra App: $AppNameIn"
Write-Output ""
}

$URL = "$uri/apps"

$theResponse = Invoke-WebRequest -Uri "${URL}" `
-Method "POST" `
-Headers @{
"Authorization"="Bearer $token"
} `
-ContentType "application/json" `
-Body "${jsonFileIn}" 2>&1 | out-null
}


function ESTABLISH_CIMITRA_API_SESSION{

$global:uri = "https://${CIMITRA_SERVER_ADDRESS}:${CIMITRA_SERVER_PORT}/api"

$payload = @{
    email = $CIMITRA_SERVER_ADMIN_ACCOUNT;
    password = $CIMITRA_SERVER_ADMIN_PASSWORD;
} | ConvertTo-Json


try{
$response = Invoke-RestMethod -Uri $uri/users/login -Method POST -Body $payload -ContentType "application/json"
}catch{
$err = "$_"
Write-Output ""
Write-Host "ERROR - Cimitra Server Return Error: $err" -ForegroundColor red -BackgroundColor white
Write-Output ""
exit 1
}
$token = $response.token 

$global:token = $response.token 

$global:headers = @{Authorization = "Bearer $token";}

}




function DISCOVER_AGENT_DETAILS{

try{
$RESPONSE = Invoke-WebRequest -Uri $uri/agent/$cimitraAgentId -Method GET -Headers $headers -UseBasicParsing -ContentType "application/json" 
}
catch{
Write-Output "The Locally Defined Cimitra Agent Does Not Exist on The Cimitra Server Specified" 
return
}

if (!($RESPONSE) -match "win32"){
CALL_ERROR_EXIT "The Locally Defined Cimitra Agent Isn't Configured to Run on The Windows Platform" 
}

if (($RESPONSE) -match "null"){
Write-Output "The Locally Defined Cimitra Agent Isn't Paired With the Cimitra Server"
return 
}

# Extract string contents between ",name:" -and- ",platform:win32,"
$Regex = [Regex]::new("(?<=,name:)(.*)(?=,platform:win32,)")

# Assign to the Regex Match of the line that contains the cimitraAgentId, remove quotes
$agentName = $Regex.Match(( $RESPONSE | Select-String -Pattern "$cimitraAgentId" ) -replace '"', "")

if (($agentName) -match "description"){

$STRING = $agentName.ToString()

$agentName = ($STRING.Split(",")[-2].Trim())
 
}



Write-Output ""
Write-Output "Cimitra Windows Agent Name: [ $agentName ]"

$global:cimitraAgentFoundInCimitraServer = $true

}


function CHECK_CONNECTIVITY{

write-output ""
write-output "START: CHECK CIMITRA AGENT INSTALL ADMIN USER SETTINGS"
write-output "------------------------------------------------------"

write-output ""
write-output "START: API Session With Cimitra Server"
write-output "--------------------------------------"

ESTABLISH_CIMITRA_API_SESSION

write-output ""
write-output "FINISH: API Session With Cimitra Server"
write-output "---------------------------------------"

# if($cimitraAgentFoundInCimitraServer){

write-output ""
write-output "START: Discover Cimitra Agent Details"
write-output "-------------------------------------"

DISCOVER_AGENT_DETAILS

write-output ""
write-output "FINISH: Discover Cimitra Agent Details"
write-output "--------------------------------------"
# }

}


function CREATE_CIMITRA_AGENT{

if ($cimitraAgentNameFound){
return
}

$CIMITRA_AGENT_NAME = $args[0]

write-output ""
write-output "-----------------------------------------"
Write-Output "Create Cimitra Agent: $CIMITRA_AGENT_NAME"
write-output "-----------------------------------------"
write-output ""


$THE_DESCRIPTION = "Cimitra Windows Agent"
$jsonFileIn = "{`"name`":`"${CIMITRA_AGENT_NAME}`",`"platform`":`"win32`",`"description`":`"${THE_DESCRIPTION}`",`"match_regex`":`"node01`"}"


$URL = "$uri/agent"



$theResponse = Invoke-WebRequest -Uri "${URL}" `
-Method "POST" `
-Headers @{
"Authorization"="Bearer $token"
} `
-ContentType "application/json" `
-Body "${jsonFileIn}" 2>&1 | out-null



}

function DOWNLOAD_CIMITRA_AGENT_BINARY{

write-output ""
Write-Output "Download Cimitra Agent EXE File"
write-output "-------------------------------"
write-output ""

$URL = "$uri/agent/${cimitraAgentId}/download"

try{

Invoke-WebRequest -Uri "${URL}" `
-Method "POST" `
-Body "host=${CIMITRA_SERVER_ADDRESS}&port=${CIMITRA_SERVER_PORT}&root=%2Fapi&type=net" `
-Headers @{
"Authorization"="Bearer $token",
"Origin: https://${CIMITRA_SERVER_ADDRESS}",
"Connection: keep-alive",
"Referer: https://${CIMITRA_SERVER_ADDRESS}/",
"Upgrade-Insecure-Requests: 1"
}`
-ContentType "application/x-www-form-urlencoded" ` -OutFile ${CIMITRA_AGENT_EXE_FILE_PATH}
}catch{

# PowerShell 6 compatibility
# https://github.com/PowerShell/PowerShell/issues/5818

Invoke-WebRequest -SkipHeaderValidation -Uri "${URL}" `
-Method "POST" `
-Body "host=${CIMITRA_SERVER_ADDRESS}&port=${CIMITRA_SERVER_PORT}&root=%2Fapi&type=net" `
-Headers @{
"Authorization"="Bearer $token",
"Origin: https://${CIMITRA_SERVER_ADDRESS}",
"Connection: keep-alive",
"Referer: https://${CIMITRA_SERVER_ADDRESS}/",
"Upgrade-Insecure-Requests: 1"
}`
-ContentType "application/x-www-form-urlencoded" ` -OutFile ${CIMITRA_AGENT_EXE_FILE_PATH}


}


}

function DOWNLOAD_CIMITRA_AGENT_CONFIG{

write-output ""
Write-Output "Download Cimitra Agent Config File"
write-output "----------------------------------"
write-output ""

$URL = "$uri/agent/${cimitraAgentId}/download"

try{
Invoke-WebRequest -Uri "${URL}" `
-Method "POST" `
-Body "host=${CIMITRA_SERVER_ADDRESS}&port=${CIMITRA_SERVER_PORT}&root=%2Fapi&type=config" `
-Headers @{
"Authorization"="Bearer $token",
"Content-Type: application/x-www-form-urlencoded",
"Origin: https://${CIMITRA_SERVER_ADDRESS}",
"Connection: keep-alive",
"Referer: https://${CIMITRA_SERVER_ADDRESS}/",
"Upgrade-Insecure-Requests: 1"
}`
-ContentType "application/x-www-form-urlencoded" ` -OutFile ${CIMITRA_AGENT_CONFIG_FILE_PATH}

}catch{
# PowerShell 6 compatibility
# https://github.com/PowerShell/PowerShell/issues/5818
Invoke-WebRequest -SkipHeaderValidation -Uri "${URL}" `
-Method "POST" `
-Body "host=${CIMITRA_SERVER_ADDRESS}&port=${CIMITRA_SERVER_PORT}&root=%2Fapi&type=config" `
-Headers @{
"Authorization"="Bearer $token",
"Content-Type: application/x-www-form-urlencoded",
"Origin: https://${CIMITRA_SERVER_ADDRESS}",
"Connection: keep-alive",
"Referer: https://${CIMITRA_SERVER_ADDRESS}/",
"Upgrade-Insecure-Requests: 1"
}`
-ContentType "application/x-www-form-urlencoded" ` -OutFile ${CIMITRA_AGENT_CONFIG_FILE_PATH}



}

}

function INSTALL_CIMITRA_AGENT{
write-output ""
Write-Output "Install Cimitra Service"
write-output "-----------------------"
write-output ""
& ${CIMITRA_AGENT_EXE_FILE_PATH} install -config "${CIMITRA_AGENT_CONFIG_FILE_PATH}"
}

function STOP_CIMITRA_AGENT{
write-output ""
Write-Output "Stop Cimitra Service"
Write-Host ""
write-output "--------------------"
Write-Host ""
Write-Host "COMMAND: Stop-Service Cimitra" -ForegroundColor blue -BackgroundColor white
Write-Host ""
try{
Stop-Service Cimitra 2>&1 | out-null
}catch{}
}

function START_CIMITRA_AGENT{
write-output ""
Write-Output "Start Cimitra Service"
write-output "---------------------"
Write-Host ""
try{
Stop-Service Cimitra 2>&1 | out-null
}catch{}

Write-Host "COMMAND: Start-Service Cimitra" -ForegroundColor blue -BackgroundColor white

Start-Service Cimitra

}

function INSTALL_AGENT_AND_IMPORT_APPS{
Write-Output "Create and Install Cimitra Agent"
CHECK_CONNECTIVITY
SEE_IF_PAIRED_CIMITRA_AGENT_EXISTS
}


function CONFIRM_AGENT_SERVICE_REGISTRY{
write-output ""
Write-Output "Confirm Cimitra Agent Service Registry Set"
write-output ""

$TEMP_FILE_ONE=New-TemporaryFile

$TEMP_FILE_TWO=New-TemporaryFile

$TEMP_FILE_THREE=New-TemporaryFile

$TEMP_FILE_FOUR=New-TemporaryFile

$CIMITRA_AGENT_CONFIG_LINE = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Cimitra' -Name ImagePath).ImagePath

# Get Config File Path - Using temp file extraction
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Cimitra' 1> $TEMP_FILE_ONE

$IMAGE_PATH = Get-Content $TEMP_FILE_ONE | Select-String -Pattern ".cfg" 

$IMAGE_PATH = $IMAGE_PATH -replace ' ', ''

$IMAGE_PATH = $IMAGE_PATH -replace '"', ''

if ( ($IMAGE_PATH).Contains("-tsspconfig")){
# Extract string contents between ",name:" -and- ",platform:win32,"
$CONFIG_REGEX = [Regex]::new("(?<=-tsspconfig)(.*)(?=)")

# Assign to the Regex Match
$CIMITRA_AGENT_CONFIG_FILE = $CONFIG_REGEX.Match( $IMAGE_PATH )
}else{

$CIMITRA_AGENT_CONFIG_FILE = $IMAGE_PATH
}

# Remove-Item -Path $TEMP_FILE_ONE -Force

$IMAGE_PATH = Get-Content $TEMP_FILE_ONE | Select-String -Pattern ".exe" 

$IMAGE_PATH = $IMAGE_PATH -replace ' ', ''

$IMAGE_PATH = $IMAGE_PATH -replace '"', ''

# Extract string contents between ",name:" -and- ",platform:win32,"
$EXE_REGEX = [Regex]::new("(?<=ImagePath:)(.*)(?=-displayname)")

# Assign to the Regex Match
$CIMITRA_AGENT_EXE_FILE = $EXE_REGEX.Match( $IMAGE_PATH )


$global:CIMITRA_AGENT_EXE_FILE_PATH = $CIMITRA_AGENT_EXE_FILE


if(Test-Path "${CIMITRA_AGENT_CONFIG_FILE}"){

if (ConfirmFromConfigFile "$CIMITRA_AGENT_CONFIG_FILE" "CIMITRA_ID"){


$CIMITRA_AGENT_UNIQUE_ID_ONE = Get-Content ${CIMITRA_AGENT_CONFIG_FILE} | Select-String -Pattern "CIMITRA_ID" 

$CIMITRA_AGENT_UNIQUE_ID_TWO = $CIMITRA_AGENT_UNIQUE_ID_ONE -replace '"', ""

$CIMITRA_AGENT_UNIQUE_ID_TWO -split "=" 1> $TEMP_FILE_THREE

$CIMITRA_AGENT_UNIQUE_ID = (Get-Content $TEMP_FILE_THREE -Tail 1)

Remove-Item -Path $TEMP_FILE_THREE -Force

$global:cimitraAgentId = "$CIMITRA_AGENT_UNIQUE_ID"

CHECK_CONNECTIVITY

LOOK_FOR_DEFINED_AGENT_ID "$CIMITRA_AGENT_UNIQUE_ID"


}else{

Write-Output "Cimitra Agent Unique ID is Not Configured"
Write-Output ""
INSTALL_AGENT_AND_IMPORT_APPS
}


}else{

Write-Host "WARNING: The Registered Cimitra Config File Does Not Exist" -ForegroundColor red -BackgroundColor white
Write-Output ""
INSTALL_AGENT_AND_IMPORT_APPS
} 

CHECK_CONNECTIVITY

if($cimitraAgentFoundInCimitraServer){
Write-Output ""
Write-Output "NOTE: Nothing to do, The Cimitra Agent is Already Installed"
Write-Output ""
return
}



}



function CHECK_FOR_BINARY_AGENT{

if(Test-Path ${CIMITRA_AGENT_EXE_FILE_PATH}){
Write-Output ""
Write-Output "Confirmed Existence of Cimitra Agent Program File: ${CIMITRA_AGENT_EXE_FILE_PATH}" 
Write-Output ""
}else{
Write-Output ""
Write-Host "ERROR - Cimitra Agent Program File: ${CIMITRA_AGENT_EXE_FILE_PATH}  : Does Not Exist" -ForegroundColor red -BackgroundColor white
Write-Output ""
Write-Output ""
STOP_CIMITRA_AGENT

DOWNLOAD_CIMITRA_AGENT_BINARY
INSTALL_CIMITRA_AGENT
START_CIMITRA_AGENT
}

}




function LOOK_FOR_DEFINED_AGENT_ID{

$DEFINED_AGENT_ID = $args[0]


$ALL_AGENTS_DUMP=New-TemporaryFile
$DEFINED_AGENT_DUMP=New-TemporaryFile
$DEFINED_AGENT_PLATFORM_LINE=New-TemporaryFile
$AGENT_ID_SPLIT=New-TemporaryFile
$AGENT_ID_TRIM=New-TemporaryFile
$NAME_LINE_OUTPUT_FILE=New-TemporaryFile


try{
Invoke-RestMethod -Uri $uri/agent -Method GET -Headers $headers -UseBasicParsing > $ALL_AGENTS_DUMP
}
catch{
Remove-Item -Path $ALL_AGENTS_DUMP -Force 2>&1 | out-null
$global:cimitraAgentIdFound = $false
CALL_ERROR_EXIT "Cannot Determine any Cimitra Agents - Please Install the Cimitra Agent Manually" 
}

$AGENT_ID_QUERY = Get-Content "$ALL_AGENTS_DUMP" | Select-String -CaseSensitive "${DEFINED_AGENT_ID}"

if (( ($AGENT_ID_QUERY).length -gt 0 )){}else{
Remove-Item -Path $ALL_AGENTS_DUMP -Force 2>&1 | out-null
$global:cimitraAgentIdFound = $false
return}

# Identify Agent and get 3 lines above and below Agent Name
Select-String -Path $ALL_AGENTS_DUMP -CaseSensitive -Pattern "\b${DEFINED_AGENT_ID}\b" -Context 3 1> $DEFINED_AGENT_DUMP

# Remove Temp File
Remove-Item -Path $ALL_AGENTS_DUMP -Force 2>&1 | out-null

$PLATFORM_LINE = (Get-Content ${DEFINED_AGENT_DUMP} | Select-String -pattern ":platform")

$NAME_LINE = (Get-Content ${DEFINED_AGENT_DUMP} | Select-String -pattern ":name")

Write-Output  "$NAME_LINE" 1>  $NAME_LINE_OUTPUT_FILE

$NAME_LINE = Get-Content $NAME_LINE_OUTPUT_FILE

# Remove Temp File
Remove-Item -Path $NAME_LINE_OUTPUT_FILE -Force 2>&1 | out-null

Write-Output "$PLATFORM_LINE" 1> $DEFINED_AGENT_PLATFORM_LINE

# See if win32 is the platform
$WIN32_COUNT = (Get-Content $DEFINED_AGENT_PLATFORM_LINE | Select-String -pattern "win32").length

# Remove Temp File
Remove-Item -Path $DEFINED_AGENT_PLATFORM_LINE -Force 2>&1 | out-null

# See if win32 is not the platform, bail out
if ($WIN32_COUNT -lt 1){
CALL_ERROR_EXIT "The Locally Defined Cimitra Agent Isn't Configured to Run on The Windows Platform" 
}

# Get last column of platform line to extract the agent name
$AGENT_NAME = ($NAME_LINE.Split(":")[-1].Trim())

Write-Output ""
Write-Output "Installed Cimitra Windows Agent Is Named: [ $AGENT_NAME ]"
Write-Output ""
Write-Output "Local Cimitra Agent Program File: ${CIMITRA_AGENT_EXE_FILE_PATH}" 
Write-Output ""
Write-Output "Local Cimitra Agent Config  File: ${CIMITRA_AGENT_CONFIG_FILE_PATH}" 
Write-Output ""

}


function LOOK_FOR_DEFINED_AGENT_NAME{

$DEFINED_AGENT_IN = $args[0]

$ALL_AGENTS_DUMP=New-TemporaryFile
$DEFINED_AGENT_DUMP=New-TemporaryFile
$DEFINED_AGENT_ID_LINE_ONE=New-TemporaryFile
$DEFINED_AGENT_ID_LINE_TWO=New-TemporaryFile
$AGENT_ID_TRIM=New-TemporaryFile
$TEMP_FILE_ONE=New-TemporaryFile


try{
Invoke-RestMethod -Uri $uri/agent -Method GET -Headers $headers -UseBasicParsing > $ALL_AGENTS_DUMP
}
catch{
Remove-Item -Path $ALL_AGENTS_DUMP -Force 2>&1 | out-null
$global:cimitraAgentIdFound = $false
CALL_ERROR_EXIT "Cannot Determine any Cimitra Agents - Please Install the Cimitra Agent Manually" 
}

$AGENT_ID_QUERY = Get-Content "$ALL_AGENTS_DUMP" | Select-String -CaseSensitive "\b${DEFINED_AGENT_IN}\b"


if ($AGENT_ID_QUERY.Length -gt 0 ){}else{
Remove-Item -Path $ALL_AGENTS_DUMP -Force 2>&1 | out-null
$global:cimitraAgentIdFound = $false
return}

# Identify Agent and get line above and below Agent Name
Select-String -Path $ALL_AGENTS_DUMP -CaseSensitive -Pattern "\b${DEFINED_AGENT_IN}\b" -Context 1 1> $DEFINED_AGENT_DUMP

# Get just the _id line
Select-String -Path $DEFINED_AGENT_DUMP -CaseSensitive -Pattern "\b:_id\b" 1> $DEFINED_AGENT_ID_LINE_ONE

Remove-Item -Path $DEFINED_AGENT_DUMP -Force 2>&1 | out-null

(Get-Content $DEFINED_AGENT_ID_LINE_ONE) -replace " ", "" 1> $DEFINED_AGENT_ID_LINE_TWO

Remove-Item -Path $DEFINED_AGENT_ID_LINE_ONE -Force 2>&1 | out-null

$ID_COUNT = (get-content $DEFINED_AGENT_ID_LINE_TWO | select-string -pattern ":_id:").length

if($ID_COUNT -gt 1 ){
Write-Output ""
Write-Host "ERROR: There are ($ID_COUNT) Cimitra Agents With The Name: $DEFINED_AGENT_IN" -ForegroundColor red -BackgroundColor white
Write-Output ""
Write-Host "Please install the Cimitra Agent Manually or Remedy This Issue" -ForegroundColor red -BackgroundColor white
Write-Output ""
Remove-Item -Path $DEFINED_AGENT_ID_LINE_TWO -Force 2>&1 | out-null
exit 1
}

$Regex = [Regex]::new("(?<=:_id:)(.*)(?=)")

$AGENT_ID = $Regex.Match(( Get-Content $DEFINED_AGENT_ID_LINE_TWO ) -replace '"', "")

Remove-Item -Path $DEFINED_AGENT_ID_LINE_TWO -Force 2>&1 | out-null

$AGENT_ID = $AGENT_ID.ToString()
$AGENT_ID = "$AGENT_ID".Trim()

if( "$AGENT_ID".Length -gt 26 ){
Write-Output ""
Write-Host "ERROR: Incorrect ID Length for Cimitra Agent: $DEFINED_AGENT_IN" -ForegroundColor red -BackgroundColor white
Write-Output ""
Write-Host "Please install the Cimitra Agent Manually or Remedy This Issue" -ForegroundColor red -BackgroundColor white
Write-Output ""
Remove-Item -Path $DEFINED_AGENT_ID_LINE_TWO -Force 2>&1 | out-null

Write-Output "Agent ID: $AGENT_ID"
exit 1
}


# Assign the Cimitra Agent's Unique ID to a Global Variable
$global:cimitraAgentId="$AGENT_ID"


# If we identified the Agent ID correctly, we should be able to get info on it
try{
Invoke-RestMethod -Uri $uri/agent/${cimitraAgentId} -Method GET -Headers $headers -UseBasicParsing > $TEMP_FILE_ONE
}
catch{
Remove-Item -Path $TEMP_FILE_ONE -Force 2>&1 | out-null
$global:cimitraAgentIdFound = $false
# If we didn't identify the Agent ID correctly, just bail out
return
}


$WIN32 = "win32"

if ((Get-Content "$TEMP_FILE_ONE" | Select-String -CaseSensitive "\b${WIN32}\b" )){}else{
Remove-Item -Path $TEMP_FILE_ONE -Force 2>&1 | out-null
$global:cimitraAgentIdFound = $false
# If we did identify what we thought was the Agent ID, but it's not Windows, bail out
return}

# Remove Temp File
Remove-Item -Path $TEMP_FILE_ONE -Force 2>&1 | out-null
Write-Output ""
Write-Output "Cimitra Windows Agent Defined: [ $DEFINED_AGENT_IN ]"
$global:cimitraAgentNameFound = $true

}



function CREATE_IMPORT_FOLDER_STRUCTURE{

$TEMP_FILE_ONE=New-TemporaryFile

Invoke-WebRequest -Uri $uri/apps -Method GET -Headers $headers -UseBasicParsing -ContentType "application/json" > $TEMP_FILE_ONE

$rootFolderIdOne = (Get-Content $TEMP_FILE_ONE | Select-String -SimpleMatch -CaseSensitive 'Home Folder -' -Context 1 | Select-Object -First 1 ) 

# Remove Quotes
$rootFolderIdOne = $rootFolderIdOne -replace '"', ''

# Remove Spaces
$rootFolderIdOne = $rootFolderIdOne -replace ' ', ''

# Extract ID Only
$Regex = [Regex]::new("(?<=,_id:)(.*)(?=,)")
$rootFolderId = $Regex.Match( $rootFolderIdOne )

Invoke-RestMethod -Uri $uri/apps/$rootFolderId/children -Method GET -Headers $headers -UseBasicParsing > $TEMP_FILE_ONE

Set-Variable -Name IMPORT_FOLDER -Value 'IMPORT' 


if ((Get-Content "$TEMP_FILE_ONE" | Select-String -CaseSensitive "\b${IMPORT_FOLDER}\b" )){
Write-Output ""
Write-Output "${IMPORT_FOLDER} - Folder Exists"
}else{
Write-Output ""
Write-Output "${IMPORT_FOLDER} - Folder Create"
CREATE_CIMITRA_FOLDER_ENTITY "${IMPORT_FOLDER}" "Cimitra Import Folder" "$rootFolderId"
}


if ((Get-Content "$TEMP_FILE_ONE") -match "${IMPORT_FOLDER}"){

$importFolderIdOne = (Get-Content $TEMP_FILE_ONE | Select-String -SimpleMatch -CaseSensitive "${IMPORT_FOLDER}" -Context 1 | Select-Object -First 1 ) 

$importFolderIdTwo = ($importFolderIdOne -split '\n')[0]

$importFolderIdThree = ( $importFolderIdTwo | %{ $_.Split(':')[1];} )

$importFolderId = $importFolderIdThree.Trim()

$global:IMPORT_FOLDER_ID = $importFolderId

Remove-Item -Path $TEMP_FILE_ONE -Force

}else{
Write-Output "Error: Cannot Create or Discover the Folder: ${IMPORT_FOLDER}"
Remove-Item -Path $TEMP_FILE_ONE -Force
exit 1
}


Invoke-RestMethod -Uri $uri/apps/$importFolderId/children -Method GET -Headers $headers -UseBasicParsing > $TEMP_FILE_ONE

Set-Variable -Name AGENT_IMPORT_FOLDER_NAME -Value $cimitraAgentName 


if ((Get-Content "$TEMP_FILE_ONE") -match "${AGENT_IMPORT_FOLDER_NAME}"){
Write-Output ""
Write-Output "${IMPORT_FOLDER} | ${AGENT_IMPORT_FOLDER_NAME} - Folder Exists"
}else{
Write-Output ""
Write-Output "${IMPORT_FOLDER} | ${AGENT_IMPORT_FOLDER_NAME} - Folder Create"
CREATE_CIMITRA_FOLDER_ENTITY "${AGENT_IMPORT_FOLDER_NAME}" "Cimitra Agent App ${IMPORT_FOLDER} | ${IMPORT_FOLDER}  Folder." "$importFolderId"
}

Invoke-RestMethod -Uri $uri/apps/$importFolderId/children -Method GET -Headers $headers -UseBasicParsing > $TEMP_FILE_ONE

if ((Get-Content "$TEMP_FILE_ONE") -match "${AGENT_IMPORT_FOLDER_NAME}"){

$agentImportFolderIdOne = (Get-Content $TEMP_FILE_ONE | Select-String -SimpleMatch -CaseSensitive "${AGENT_IMPORT_FOLDER_NAME}" -Context 1 | Select-Object -First 1 ) 

$agentImportFolderIdTwo = ($agentImportFolderIdOne -split '\n')[0]

$agentImportFolderIdThree = ( $agentImportFolderIdTwo | %{ $_.Split(':')[1];} )

$agentImportFolderId = $agentImportFolderIdThree.Trim()

$global:CIMITRA_AGENT_IMPORT_FOLDER_ID = "$agentImportFolderId"

Remove-Item -Path $TEMP_FILE_ONE -Force

}else{
Write-Output "Error: Cannot Create or Discover the Folder: ${AGENT_IMPORT_FOLDER_NAME}"
Remove-Item -Path $TEMP_FILE_ONE -Force
exit 1
}

}

function POWERSHELL_SCRIPT_EXCUTION_RIGHTS{

$SCRIPT_INSTALLATION_DIRECTORY = $args[0]

try{
Set-Location -Path $SCRIPT_INSTALLATION_DIRECTORY
}catch{
Write-Output ""
Write-Output "Error: Cannot access directory: $SCRIPT_INSTALLATION_DIRECTORY"
Write-Output ""
exit 1
}

Write-Output ""
Write-Host "Configuring Windows to Allow PowerShell Scripts to Run" -ForegroundColor blue -BackgroundColor white
Write-Output ""

Unblock-File * 

try{
powershell.exe -NonInteractive -Command Set-ExecutionPolicy Unrestricted 2>&1 | out-null
}catch{
    try{
    Set-ExecutionPolicy Unrestricted 2>&1 | out-null
    }catch{}
}

try{
powershell.exe -NonInteractive -Command Set-ExecutionPolicy Bypass 2>&1 | out-null
}catch{
    try{
    Set-ExecutionPolicy Bypass 2>&1 | out-null
    }catch{}
}

try{
powershell.exe -NonInteractive -Command Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process 2>&1 | out-null
}catch{
    try{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process 2>&1 | out-null
    }catch{}
}

try{
powershell.exe -NonInteractive -Command Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser 2>&1 | out-null
}catch{
    try{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser 2>&1 | out-null
    }catch{}
}

try{
powershell.exe -NonInteractive -Command Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine 2>&1 | out-null
}catch{
    try{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine 2>&1 | out-null
    }catch{}
}

}


function SEE_IF_PAIRED_CIMITRA_AGENT_EXISTS{

$CIMITRA_AGENT_NAME_ONE = $cimitraAgentName

$CIMITRA_AGENT_NAME = $CIMITRA_AGENT_NAME_ONE -replace ' ', "_"

LOOK_FOR_DEFINED_AGENT_NAME "${CIMITRA_AGENT_NAME}"


if($cimitraAgentIdFound){
# Stop the Cimitra Service
try{
Stop-Service Cimitra 2>&1 | out-null
}catch{}
# Create a Cimitra Agent
}else{
CREATE_CIMITRA_AGENT "${CIMITRA_AGENT_NAME}"
LOOK_FOR_DEFINED_AGENT_NAME "${CIMITRA_AGENT_NAME}"
}

New-Item -Path $CIMITRA_AGENT_CONFIG_FILE_PATH -ItemType Directory -Force 2>&1 | out-null
Remove-Item -Path $CIMITRA_AGENT_CONFIG_FILE_PATH -Force 2>&1 | out-null
DOWNLOAD_CIMITRA_AGENT_BINARY
DOWNLOAD_CIMITRA_AGENT_CONFIG
INSTALL_CIMITRA_AGENT
START_CIMITRA_AGENT

}


function CONFIRM_AGENT_INSTALLATION{
write-output ""
Write-Output "Confirm Cimitra Agent Installation"
write-output ""

$TEMP_FILE_ONE=New-TemporaryFile

$TEMP_FILE_TWO=New-TemporaryFile

$TEMP_FILE_THREE=New-TemporaryFile

$TEMP_FILE_FOUR=New-TemporaryFile

# Get Agent CFG File Path - Using string extraction

$IMAGE_PATH = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Cimitra' -Name ImagePath).ImagePath;

$AGENT_CONFIG_ONE = $IMAGE_PATH | Select-String -Pattern '(?ms)-tsspconfig "(.*?)"' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$AGENT_CONFIG_TWO = $AGENT_CONFIG_ONE | Select-String -Pattern '(?ms)"(.*?)"' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$CIMITRA_AGENT_CONFIG_FILE = $AGENT_CONFIG_TWO -replace '"', ""

$global:CIMITRA_AGENT_CONFIG_FILE_PATH = $CIMITRA_AGENT_CONFIG_FILE

# Get Agent EXE File Path - Using string extraction

$IMAGE_PATH = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Cimitra' -Name ImagePath).ImagePath;

$AGENT_EXE_AND_DISPLAYNAME = $IMAGE_PATH | Select-String -Pattern '(?ms)"(.*?)-displayname' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$AGENT_EXE_AND_PATH = $AGENT_EXE_AND_DISPLAYNAME | Select-String -Pattern '(?ms)"(.*?)"' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$AGENT_EXE = $AGENT_EXE_AND_PATH -replace '"', ""

$global:CIMITRA_AGENT_EXE_FILE_PATH = $AGENT_EXE


if($removeCimitraAgentAndConfig){
# Remove the Cimitra Binary File
Remove-Item -Path ${AGENT_EXE} -Force 2>&1 | out-null
SEE_IF_PAIRED_CIMITRA_AGENT_EXISTS
}


if(Test-Path "${CIMITRA_AGENT_CONFIG_FILE}"){

    if (ConfirmFromConfigFile "$CIMITRA_AGENT_CONFIG_FILE" "CIMITRA_ID"){

    $CIMITRA_AGENT_UNIQUE_ID_ONE = Get-Content ${CIMITRA_AGENT_CONFIG_FILE} | Select-String -Pattern "CIMITRA_ID" 

    $CIMITRA_AGENT_UNIQUE_ID_TWO = $CIMITRA_AGENT_UNIQUE_ID_ONE -replace '"', ""

    $CIMITRA_AGENT_UNIQUE_ID_TWO -split "=" 1> $TEMP_FILE_THREE

    $CIMITRA_AGENT_UNIQUE_ID = (Get-Content $TEMP_FILE_THREE -Tail 1)

    Remove-Item -Path $TEMP_FILE_THREE -Force

    CHECK_CONNECTIVITY

    LOOK_FOR_DEFINED_AGENT_ID "$CIMITRA_AGENT_UNIQUE_ID"


    $global:cimitraAgentId = "$CIMITRA_AGENT_UNIQUE_ID"

    }else{
    Write-Output "Cimitra Agent Unique ID is Not Configured"
    Write-Output ""
    INSTALL_AGENT_AND_IMPORT_APPS
    }


}else{

INSTALL_AGENT_AND_IMPORT_APPS
} 

CHECK_CONNECTIVITY



if($cimitraAgentFoundInCimitraServer){

CREATE_CIMITRA_APPS
Write-Output ""
Write-Output ""
exit 0
}



}

function CHECKUP_CIMITRA_SERVICE{

$ServiceName = 'Cimitra'

Write-Output "Check Cimitra Service"
write-output "---------------------"
Write-Host "COMMAND: Get-Service Cimitra" -ForegroundColor blue -BackgroundColor white


Get-Service -Name $ServiceName

$arrService = Get-Service -Name $ServiceName

if ($arrService.Status -ne 'Running')
{

    Write-Host "COMMAND: Start-Service Cimitra" -ForegroundColor blue -BackgroundColor white

    Start-Service $ServiceName
    write-host $arrService.status


    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Cimitra Service is now Running'
    }

}
}



function INSTALL_CIMITRA_COMMAND{


$CIMITRA_DOWNLOAD = "https://raw.githubusercontent.com/cimitrasoftware/agent/master/cimitra.ps1"

$CIMITRA_DOWNLOAD_OUT_FILE = "${CIMITRA_EXE_BASE_PATH}\cimitra.ps1"

Write-Output ""
write-output "Download From GitHub Cimitra Script: cimitra.ps1"
Write-Output ""
Invoke-RestMethod $CIMITRA_DOWNLOAD -OutFile $CIMITRA_DOWNLOAD_OUT_FILE -UseBasicParsing


try{
setx /M PATH "%PATH%;${CIMITRA_EXE_BASE_PATH}" 2>&1 | out-null
}catch{}

}



function MAIN{

CONFIRM_AGENT_SERVICE_REGISTRY
CHECK_FOR_BINARY_AGENT

if($cimitraServiceFound){
CONFIRM_AGENT_INSTALLATION

if(!($cimitraAgentFoundInCimitraServer)){
return
}
CHECKUP_CIMITRA_SERVICE
CREATE_CIMITRA_APPS
}else{
INSTALL_AGENT_AND_IMPORT_APPS
CREATE_CIMITRA_APPS
}
}

MAIN


function REMOVE_AGENT_AND_CONFIG()
{
STOP_CIMITRA_AGENT
Remove-Item -Path ${CIMITRA_AGENT_CONFIG_FILE_PATH} -Force 2>&1 | out-null
Remove-Item -Path ${CIMITRA_AGENT_EXE_FILE_PATH} -Force 2>&1 | out-null
}

if(!($cimitraAgentFoundInCimitraServer)){
REMOVE_AGENT_AND_CONFIG
MAIN
}



INSTALL_CIMITRA_COMMAND

Write-Output ""
Write-Output "----------------------------------------------------------"
Write-Host "FINISH - CIMITRA WINDOWS AGENT COMMAND LINE INSTALL SCRIPT" -ForegroundColor Green
Write-Output ""
