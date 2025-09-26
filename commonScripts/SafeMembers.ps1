#Safe Members and Permissions

#Example Environment:
#This is a PrivilegeCloud environment, although the code is the same for SelfHosted environments, just the authentication line is different
#Keep in mind, if a safe member found is a group, the script does not have the logic to parse the group for group members (regardless of EPVGroup or ADGroup)

param($targetSafe)

#Import the module if not already
import-module vpasmodule

#Basic check if targetSafe was not passed
if([String]::IsNullOrEmpty($targetSafe)){
    Write-Host "ENTER TARGET SAFE: " -ForegroundColor Yellow -NoNewline
    $targetSafe = Read-Host

    #Basic check if targetSafe was still not passed
    if([String]::IsNullOrEmpty($targetSafe)){
        Write-Host "NO SAFE NAME PROVIDED...EXITING SCRIPT" -ForegroundColor Red
        return $false
    }
}

#Generate a credential object that will authenticate into your environment
$creds = Get-Credential

#Change these values based on your environment
$PVWA = "vman.privilegecloud.cyberark.cloud"
$IdentityURL = "ABC1234.id.cyberark.cloud"

#Generate login token
$token = New-VPASToken -PVWA $PVWA -AuthType ispss_oauth -IdentityURL $IdentityURL -creds $creds

#Notice the AuthType is set to "ispss_oauth", this will use a local @cyberark.cloud account via oauth for PrivilegeCloud solutions
#For SelfHosted environments, typically a local EPV account is created and used for API purposes
#For SelfHosted solutions, there is no need for an IdentityURL
#The token line would look like this (assuming CyberArk auth):
#    $token = New-VPASToken -PVWA $PVWA -AuthType cyberark -creds $creds

#Basic error handling if authentication failed, the script will exit
if(!$token){
    Write-Host "FAILED TO AUTHENTICATE INTO $PVWA...EXITING SCRIPT" -ForegroundColor Red
    return $false
}

Write-Host "=== BEGIN PROCESS ===" -ForegroundColor Cyan


#Query the environment first to see if the Safe exists
$DoesSafeExist = Get-VPASSafeDetails -safe $targetSafe
if(!$DoesSafeExist){
    #This means the safe does not exist, and so nothing to report on
    Write-Host "$targetSafe DOES NOT EXIST...EXITING SCRIPT" -ForegroundColor Red
    Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
    return $false
}
else{
    #The safe does exist, lets retrieve all safe members from the safe and permissions
    Write-Host "FETCHING ALL SAFE MEMBERS AND PERMISSIONS FROM SAFE: $targetSafe" -ForegroundColor Green
    $AllSafeMembers = Get-VPASSafeMembers -safe $targetSafe -IncludePredefinedMembers -ExportToCSV -CSVDirectory $PSScriptRoot
    #The output will be stored in the location of where the script is saved to: $PSScriptRoot
    #The CSVDirectory can be changed to anything: "C:\\Temp" for example

    #Basic error handling if retrieving data has failed
    if($AllSafeMembers){
        Write-Host "ALL SAFE MEMBERS FROM SAFE: $targetSafe HAVE BEEN RETURNED WITH THEIR PERMISSIONS" -ForegroundColor Green
    }
    else{
        Write-Host "ERROR GETTING SAFE MEMBERS FROM SAFE...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
}

Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
return $AllSafeMembers