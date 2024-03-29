﻿# Cimitra Windows Agent Control Script
# Version 1.0
# Release Date: 4/15/2021
# Author: Tay Kratzer tay@cimitra.com
# -------------------------------------------------
# Provides: cimitra
# Short-Description: Cimitra Agent Control Script

$THIS_SCRIPT = $PSCommandpath

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
#  $global:proceedWithInstall = $true
# 


# $script:CIMITRA_AGENT_IMPORT_FOLDER="$agentImportFolderId"

if(test-path $CIMITRA_AGENT_CONFIG_FILE_PATH){
$global:cimitraCfgFound = $true
}

if(test-path $CIMITRA_AGENT_EXE_FILE_PATH){
$global:cimitraExeFound = $true
}

function CALL_ERROR_EXIT{
$ErrorMessageIn=$args[0]
Write-Output ""
Write-Host "ERROR: $ErrorMessageIn" -ForegroundColor red -BackgroundColor white
Write-Output ""
exit 1
}


function CONFIRM_AGENT_SERVICE_REGISTRY{


$CIMITRA_AGENT_CONFIG_LINE = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Cimitra' -Name ImagePath).ImagePath 2>&1 | out-null

$CIMITRA_AGENT_CONFIG_LINE = $CIMITRA_AGENT_CONFIG_LINE | Out-String

if (($CIMITRA_AGENT_CONFIG_LINE).Contains("Cannot find path")){
$global:cimitraAgentIdFound = $false
CALL_ERROR_EXIT "The Cimitra Agent Service Does Not Exist"
exit 1
}

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

function INSTALL_CIMITRA_COMMAND{

Copy-Item -Path "$THIS_SCRIPT" -Destination "${CIMITRA_EXE_BASE_PATH}" -Force

try{
setx /M PATH "%PATH%;${CIMITRA_EXE_BASE_PATH}" 2>&1 | out-null
}catch{}

Write-Output "Cimitra Agent Control Command Installed"
write-output "---------------------"
Write-Host "COMMAND: cimitra" -ForegroundColor blue -BackgroundColor white
write-output "---------------------"
Write-Output ""
Write-Output 'NOTE - The command:  cimitra   : should be available in any new PowerShell session.'
Write-Output ""
}


if ($args[0] | Select-String "install" )
{
INSTALL_CIMITRA_COMMAND
exit 0
}

if ($args[0] | Select-String "-i" )
{
INSTALL_CIMITRA_COMMAND
exit 0
}


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
Write-Host "Cimitra Agent Control Commands"
Write-Host ""
Write-Host "Usage: cimitra {start|stop|restart|status|get}"
Write-Host ""
DISCOVER_MODULES
exit 0
}


function GET_MODULE{

$MODULE_TO_GET = $args[0]
$MODULE_TO_GET_LENGTH = ( $args[0] | Out-String ).Length

Write-Output ""


if($MODULE_TO_GET_LENGTH -lt 1){
Write-Output "No Module Specified"
Write-Output ""
Write-Output "Modules are located at: https://github.com/cimitrasoftware/win-api-<module name>"
Write-Output ""
Write-Output "Go to: https://github.com/cimitrasoftware to find repositories"
Write-Output ""
Write-Output "Example: cimitra get ad (get the Active Directory Module>"
Write-Output ""
exit 1
}


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
Invoke-WebRequest -ErrorAction Stop $CIMITRA_DOWNLOAD -OutFile $CIMITRA_DOWNLOAD_OUT_FILE -UseBasicParsing 2>&1 | out-null
}catch{
$global:proceedWithInstall = $false
}

if($proceedWithInstall){
.($CIMITRA_DOWNLOAD_OUT_FILE)
}else{

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

$TEMP_FILE_ONE=New-TemporaryFile

Get-Process cimagent | fl 1> $TEMP_FILE_ONE

$ID_LINE = (Select-String -Path $TEMP_FILE_ONE  -SimpleMatch "Id" ) -replace ' ', ''

Remove-Item -Path $TEMP_FILE_ONE -Force

$CIMITRA_AGENT_PID = ($ID_LINE.Split("Id:")[-1].Trim())

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
Write-Output ""
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

$MODULE_FILE_EXISTS = Test-Path $MODULE_RUN_FILE

if(!($MODULE_FILE_EXISTS)){
Write-Output ""
Write-Output "Cannot Locate Module Run File: $MODULE_RUN_FILE"
Write-Output ""
return
}

Set-Location -Path "$MODULE_PATH"

.($MODULE_RUN_FILE)

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