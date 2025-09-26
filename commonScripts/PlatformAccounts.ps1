#Platform Accounts

#Example Environment:
#This is a PrivilegeCloud environment, although the code is the same for SelfHosted environments, just the authentication line is different
#This is an exact text search, simulating using the search bar in PVWA and filtering to the target value
#This will only return details of the accounts as you would see under the Accounts Details page
#This will NOT pull any secrets and this will NOT activate any exclusivity or One Time Password workflows

param($targetPlatform)

#Import the module if not already
import-module vpasmodule

#Basic check if targetPlatform was not passed
if([String]::IsNullOrEmpty($targetPlatform)){
    Write-Host "ENTER TARGET PLATFORM (FOR EXAMPLE: WinDomain): " -ForegroundColor Yellow -NoNewline
    $targetPlatform = Read-Host

    #Basic check if targetPlatform was still not passed
    if([String]::IsNullOrEmpty($targetPlatform)){
        Write-Host "NO PLATFORM PROVIDED...EXITING SCRIPT" -ForegroundColor Red
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


#Query the environment for the target value
$SearchReturn = Get-VPASAccountDetails -platform "$targetPlatform" -ExactMatch -ExportToCSV -CSVDirectory $PSScriptRoot
#The output will be stored in the location of where the script is saved to: $PSScriptRoot
#The CSVDirectory can be changed to anything: "C:\\Temp" for example

#Basic error handling if retrieving data has failed
if($SearchReturn){
    Write-Host "RETURNING ACCOUNTS THAT WERE PICKED UP VIA SEARCH QUERY: $targetPlatform" -ForegroundColor Green
}
else{
    Write-Host "ERROR GETTING ACCOUNTS...EXITING SCRIPT" -ForegroundColor Red
    Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
    return $false
}


Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
return $SearchReturn