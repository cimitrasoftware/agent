# Cimitra Windows Agent Control Script
# Version 1.0
# Author: Tay Kratzer tay@cimitra.com
# -------------------------------------------------
# Provides: cimitra
# Short-Description: Cimitra Agent Control Script

$CIMITRA_RUNNING = $true
$scriptName = Split-Path -leaf $PSCommandpath


$global:TEMP_FILE_ONE=New-TemporaryFile
$global:TEMP_FILE_TWO=New-TemporaryFile
$global:cimitraCfgFound = $false
$global:cimitraExeFound = $false
$global:CIMITRA_AGENT_CONFIG_FILE_PATH = "c:\cimitra\cimitra.cfg"
$global:CIMITRA_AGENT_EXE_FILE_PATH = "c:\cimitra\cimagent.exe"
$global:CIMITRA_EXE_BASE_PATH = "c:\cimitra"
$global:CIMITRA_SCRIPT_BASE_PATH = "${CIMITRA_EXE_BASE_PATH}\scripts"
$global:proceedWithInstall = $true


# $script:CIMITRA_AGENT_IMPORT_FOLDER="$agentImportFolderId"

if(test-path $CIMITRA_AGENT_CONFIG_FILE_PATH){
$global:cimitraCfgFound = $true
}

if(test-path $CIMITRA_AGENT_EXE_FILE_PATH){
$global:cimitraExeFound = $true
}

function CONFIRM_AGENT_SERVICE_REGISTRY{

# Get Agent CONFIG File Path - Using string extraction

$IMAGE_PATH=New-TemporaryFile

$IMAGE_PATH = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Cimitra' -Name ImagePath).ImagePath;

$AGENT_CONFIG_ONE = $IMAGE_PATH | Select-String -Pattern '(?ms)-tsspconfig "(.*?)"' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$AGENT_CONFIG_TWO = $AGENT_CONFIG_ONE | Select-String -Pattern '(?ms)"(.*?)"' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$CIMITRA_AGENT_CONFIG_FILE = $AGENT_CONFIG_TWO -replace '"', ""

$global:CIMITRA_AGENT_CONFIG_FILE_PATH = ${CIMITRA_AGENT_CONFIG_FILE}

# Get Agent EXE File Path - Using string extraction

$IMAGE_PATH = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Cimitra' -Name ImagePath).ImagePath;

$AGENT_EXE_AND_DISPLAYNAME = $IMAGE_PATH | Select-String -Pattern '(?ms)"(.*?)-displayname' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$AGENT_EXE_AND_PATH = $AGENT_EXE_AND_DISPLAYNAME | Select-String -Pattern '(?ms)"(.*?)"' -AllMatches | foreach { $_.Matches | foreach {$_.Groups[0].Value}}

$AGENT_EXE = $AGENT_EXE_AND_PATH -replace '"', ""

$global:CIMITRA_AGENT_EXE_FILE_PATH = $AGENT_EXE

$global:CIMITRA_EXE_BASE_PATH = Split-Path -Path $CIMITRA_AGENT_EXE_FILE_PATH

$global:CIMITRA_SCRIPT_BASE_PATH = "${CIMITRA_EXE_BASE_PATH}\scripts"

}

CONFIRM_AGENT_SERVICE_REGISTRY


$global:ARGS_ONE = $args[0]
$global:ARGS_TWO = $args[1]


function DISCOVER_MODULES{

$MODULE_ROOT_PATH = ${CIMITRA_SCRIPT_BASE_PATH}


if(!(Test-Path -Path "${MODULE_ROOT_PATH}")){
return
}

if((Get-ChildItem "${MODULE_ROOT_PATH}"  -Directory | Measure-Object | %{$_.Count}) -eq 0){
return
}

$LIST_OF_MODULES = Get-ChildItem "${MODULE_ROOT_PATH}" -Directory -Name

Write-Output "Or use the folowing installed Cimitra API Modules:"
Write-Output ""

foreach ($i in $LIST_OF_MODULES){
Write-Output "cimitra ${i}"
Write-Output ""
}

}

# Show Help
function ShowHelp{
Write-Host ""
Write-Host "Usage: cimitra {start|stop|restart|status}"
Write-Host ""
DISCOVER_MODULES
exit 0
}


function GET_MODULE{

$MODULE_TO_GET = $args[0]

Write-Output "Install Cimitra Integration Module: [ ${MODULE_TO_GET} ]"

$MODULE_ROOT_PATH = ${CIMITRA_SCRIPT_BASE_PATH}

$NEW_MODULE_PATH = "$MODULE_ROOT_PATH\$MODULE_TO_GET"

try{
New-Item -Path "${MODULE_ROOT_PATH}" -ItemType "directory" 2>&1 | out-null
}catch{}

$TEMP_DIR = $env:TEMP

try{
New-Item -Path "${NEW_MODULE_PATH}" -ItemType "directory" 2>&1 | out-null
}catch{}

Set-Location -Path "${NEW_MODULE_PATH}"


$CIMITRA_DOWNLOAD = "https://raw.githubusercontent.com/cimitrasoftware/win-api-${MODULE_TO_GET}/master/install.ps1"

$CIMITRA_DOWNLOAD_OUT_FILE = "$TEMP_DIR\install.ps1"

Write-Output ""
write-output "Download From GitHub Cimitra Script: $CIMITRA_DOWNLOAD"
Write-Output ""

try{
Invoke-WebRequest $CIMITRA_DOWNLOAD -OutFile $CIMITRA_DOWNLOAD_OUT_FILE -UseBasicParsing 2>&1 | out-null
}catch{
$global:proceedWithInstall = $false
}

if($proceedWithInstall){
& $CIMITRA_DOWNLOAD_OUT_FILE
}else{
Write-Output ""
write-output "Unable to Install Module: [ ${MODULE_TO_GET} ]"
Write-Output ""
}


}


function STOP_AGENT{

$AGENT_RUNNING = ((Get-Service Cimitra | fl | Out-String) -split '\n' | Select-String -Pattern 'Status' -CaseSensitive) -replace " ", "" -Match "Status:Running"

if ($AGENT_RUNNING){

    try{
    Stop-Service Cimitra
    Write-Output "Stopped Cimitra Agent"
    }catch{}


}else{
Write-Output "Cimitra Agent is not running"
}

}


function START_AGENT{
try{
Start-Service Cimitra
    Write-Output "Started Cimitra Agent"
}catch{}
}

function AGENT_STATUS{

$AGENT_RUNNING = ((Get-Service Cimitra | fl | Out-String) -split '\n' | Select-String -Pattern 'Status' -CaseSensitive) -replace " ", "" -Match "Status:Running"

if($AGENT_RUNNING){
$CIMITRA_AGENT_PID =  (((cmd /c sc queryex Cimitra | findstr PID) -split ":" | select -Skip 1) ).trim()
Write-Output "Cimitra Agent Service is running on PID: ${CIMITRA_AGENT_PID}"
}else{
Write-Output "Cimitra Agent Service is not running"
}

}

function RESTART_AGENT{
AGENT_STATUS
STOP_AGENT
START_AGENT
AGENT_STATUS
}




function CHECK_ADMIN_LEVEL{

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Output ""
Write-Warning "Insufficient permissions to run this command. Open the PowerShell console as an administrator and run this script again."
exit 0
}

}
CHECK_ADMIN_LEVEL

if (Write-Output $args | Select-String "\-h\b|\-help\b" )
{
ShowHelp
}


function RUN_MODULE{

if(!($ARGS_ONE)){
ShowHelp
}

$MODULE_ROOT_PATH = ${CIMITRA_SCRIPT_BASE_PATH}

$LIST_OF_MODULES = Get-ChildItem "$MODULE_ROOT_PATH" -Directory -Name

foreach ($i in $LIST_OF_MODULES){

if($i -eq $ARGS_ONE){

$MODULE_PATH = "${MODULE_ROOT_PATH}\$i"

$MODULE_RUN_FILE = "${MODULE_PATH}\${i}.ps1"

# Write-Output "$MODULE_RUN_FILE"

$MODULE_FILE_EXISTS = Test-Path $MODULE_RUN_FILE


if(!($MODULE_FILE_EXISTS)){
Write-Output ""
Write-Output "Cannot Locate Module Run File: $MODULE_RUN_FILE"
Write-Output ""
return
}

Set-Location -Path "$MODULE_PATH"

& $MODULE_RUN_FILE

}

}


}



Switch ($args[0])
{
    "stop" { STOP_AGENT }
    "start" { START_AGENT }
    "restart" { RESTART_AGENT }
    "status" { AGENT_STATUS }
     "help" { ShowHelp }
     "get" { GET_MODULE $args[1] }
     default { RUN_MODULE }
}