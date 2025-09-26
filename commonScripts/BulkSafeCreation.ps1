#Bulk Safe Creation

#Example Environment:
#This is a PrivilegeCloud environment, although the code is the same for SelfHosted environments, just the authentication line is different
#This environment only has one CPM that will be assigned to safes - PasswordManager
#This script will add an internal role "Privilege Cloud Administrators" with full permissions to each safe

#Assume you have a CSV file located in C:\\Temp\\safeimport.cvs that looks like this:
#    SafeName
#    TestSafe01
#    TestSafe02
#    TestSafe03

param($csv)

#Import the module if not already
import-module vpasmodule

#Basic check if csv was not passed
if([String]::IsNullOrEmpty($csv)){
    Write-Host "ENTER TARGET CSV (FOR EXAMPLE: C:\\Temp\\safeimport.csv): " -ForegroundColor Yellow -NoNewline
    $csv = Read-Host

    #Basic check if csv was still not passed
    if([String]::IsNullOrEmpty($csv)){
        Write-Host "NO CSV PROVIDED...EXITING SCRIPT" -ForegroundColor Red
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


#Import the provided CSV file
try{
    $ImportData = Import-Csv -Path $csv
}catch{
    #Basic check if importing the CSV failed (failed to read file, file does not exist, etc.)
    Write-Host "ERROR IMPORTING CSV...EXITING SCRIPT" -ForegroundColor Red
    Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
    return $false
}

#Loop through every entry and create a safe per record
foreach($rec in $ImportData){
    #Get the safe name
    $safeName = $rec.SafeName

    #Query the environment first to see if the Safe already exists
    $DoesSafeExist = Get-VPASSafeDetails -safe $SafeName
    if(!$DoesSafeExist){
        #This means the safe does not exist, lets create it
        $CreateSafe = Add-VPASSafe -safe $SafeName -passwordManager PasswordManager -numberOfDaysRetention 7

        #Basic error handling if safe creation fails
        if(!$CreateSafe){
            Write-Host "FAILED TO CREATE SAFE $SafeName...EXITING SCRIPT" -ForegroundColor Red
            Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
            return $false
        }
        else{
            Write-Host "SUCCESSFULLY CREATED SAFE $SafeName" -ForegroundColor Green
        }
    }
    else{
        Write-Host "$SafeName ALREADY EXISTS...SKIPPING SAFE CREATION" -ForegroundColor DarkYellow
    }

    #Safe was created, now we want to add the role "Privilege Cloud Administrators"
    $DoesMemberExist = Get-VPASSafeMemberSearch -safe $SafeName -member "Privilege Cloud Administrators"
    if(!$DoesMemberExist){
        #This means that Privilege Cloud Administrators is not found on the safe, lets add it with full permissions
        $AddMember = Add-VPASSafeMember -member "Privilege Cloud Administrators" -safe $SafeName -MemberType Role -searchin Vault -AllPerms

        #Basic error handling if adding member fails
        if(!$AddMember){
            Write-Host "FAILED TO ADD Privilege Cloud Administrators TO $SafeName...EXITING SCRIPT" -ForegroundColor Red
            Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
            return $false
        }
        else{
            Write-Host "SUCCESSFULLY ADDED Privilege Cloud Administrators TO SAFE $SafeName" -ForegroundColor Green
        }
    }
    else{
        Write-Host "Privilege Cloud Administrators ALREADY EXISTS AS A SAFE MEMBER...SKIPPING SAFE MEMBER ADDITION" -ForegroundColor DarkYellow
    }
}

Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
return $true

