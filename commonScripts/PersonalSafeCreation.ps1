#Personal Safe Creation and Account onboarding

#Example Environment:
#User accounts will always follow this format: vadim (unprivileged acct) + adm-vadim (privileged acct)
#Personal safes follow this format: pSafe-vman-vadim
#There is only one CPM in this environment: PasswordManager
#Personal safes are set with a default retention period of 7 days
#Every personal safe should contain the following users:
#    target user unprivileged account with Use, List, and Retrieve permissions
#    Administrator with full permissions
#    Vault Admins with full permissions
#    Custom AD group called "SafeManager" with List, Manage safe, Manage Safe Members, View Audit Log, and View safe members permissions
#Platform we will use to onboard the adm account will be: WIN-DOM-7DAY-OTP-SUN
#In this environment, we auto assign the reconcile account, so when the account is added, we need to run a reconcile on the account
#This is a SelfHosted environment, although the code is the same for privilege cloud environments, just the authentication line is different

param($targetUser)

#Import the module if not already
import-module vpasmodule

#Basic check if targetUser was not passed
if([String]::IsNullOrEmpty($targetUser)){
    Write-Host "ENTER TARGET USER: " -ForegroundColor Yellow -NoNewline
    $targetUser = Read-Host
}

#Generate a credential object that will authenticate into your environment
$creds = Get-Credential

#Change the value based on your environment
$PVWA = "components.vman.com"

#Generate login token
$token = New-VPASToken -PVWA $PVWA -AuthType cyberark -creds $creds

#Notice the AuthType is set to "cyberark", this will use a local EPV account for SelfHosted solutions
#For PrivilegeCloud environments, typically an Oauth account is created and IdentityURL will need to be provided
#The token line would look like this (change IdentityURL to your environment URL):
#    $IdentityURL = "ABC1234.id.cyberark.cloud"
#    $token = New-VPASToken -PVWA $PVWA -AuthType ispss_oauth -creds $creds -IdentityURL $IdentityURL

#Basic error handling if authentication failed, the script will exit
if(!$token){
    Write-Host "FAILED TO AUTHENTICATE INTO $PVWA...EXITING SCRIPT" -ForegroundColor Red
    return $false
}

Write-Host "=== BEGIN PROCESS ===" -ForegroundColor Cyan

#Build SafeName following naming convention
$SafeName = "pSafe-vman-$targetUser"

#Query the environment first to see if the Safe already exists
$DoesSafeExist = Get-VPASSafeDetails -safe $SafeName
if(!$DoesSafeExist){
    #This means the safe does not exist, lets create it
    $CreateSafe = Add-VPASSafe -safe $SafeName -passwordManager PasswordManager -numberOfDaysRetention 7 -Description "Personal Safe for $targetUser"

    #Basic error handling if safe creation fails
    if(!$CreateSafe){
        Write-Host "STEP 1 / 4) FAILED TO CREATE SAFE $SafeName...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
    else{
        Write-Host "STEP 1 / 4) SUCCESSFULLY CREATED SAFE $SafeName" -ForegroundColor Green
    }
}
else{
    Write-Host "STEP 1 / 4) $SafeName ALREADY EXISTS...SKIPPING SAFE CREATION" -ForegroundColor DarkYellow
}

#Now we need to add the following safe members as an example:
#    Administrator (Local EPV Account) - full permissions
#    Vault Admins (Local EPV Group) - full permissions
#    targetUser (Domain User in vman.com) - Use, list, retrieve
#    SafeManager (AD Group in vman.com) - List, Manage safe, Manage Safe Members, View Audit Log, and View safe members

#We will do the following steps for each member above

#Administrator Section
#Query if Administrator exists on the safe already
$DoesMemberExist = Get-VPASSafeMemberSearch -safe $SafeName -member "Administrator"
if(!$DoesMemberExist){
    #This means that Administrator is not found on the safe, lets add it with full permissions
    $AddMember = Add-VPASSafeMember -member "Administrator" -safe $SafeName -MemberType User -searchin Vault -AllPerms

    #Basic error handling if adding member fails
    if(!$AddMember){
        Write-Host "STEP 2a / 4) FAILED TO ADD Administrator TO $SafeName...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
    else{
        Write-Host "STEP 2a / 4) SUCCESSFULLY ADDED Administrator TO SAFE $SafeName" -ForegroundColor Green
    }
}
else{
    Write-Host "STEP 2a / 4) Administrator ALREADY EXISTS AS A SAFE MEMBER...SKIPPING SAFE MEMBER ADDITION" -ForegroundColor DarkYellow
}

#Vault Admins Section
#Query if Vault Admins exists on the safe already
$DoesMemberExist = Get-VPASSafeMemberSearch -safe $SafeName -member "Vault Admins"
if(!$DoesMemberExist){
    #This means that Vault Admins is not found on the safe, lets add it with full permissions
    $AddMember = Add-VPASSafeMember -member "Vault Admins" -safe $SafeName -MemberType Group -searchin Vault -AllPerms

    #Basic error handling if adding member fails
    if(!$AddMember){
        Write-Host "STEP 2b / 4) FAILED TO ADD Vault Admins TO $SafeName...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
    else{
        Write-Host "STEP 2b / 4) SUCCESSFULLY ADDED Vault Admins TO SAFE $SafeName" -ForegroundColor Green
    }
}
else{
    Write-Host "STEP 2b / 4) Vault Admins ALREADY EXISTS AS A SAFE MEMBER...SKIPPING SAFE MEMBER ADDITION" -ForegroundColor DarkYellow
}

#targetUser Section
#Query if targetUser exists on the safe already
$DoesMemberExist = Get-VPASSafeMemberSearch -safe $SafeName -member "$targetUser"
if(!$DoesMemberExist){
    #This means that targetUser is not found on the safe, lets add it with Use, list, retrieve permissions
    $AddMember = Add-VPASSafeMember -member "$targetUser" -safe $SafeName -MemberType User -searchin vman.com -UseAccounts -ListAccounts -RetrieveAccounts

    #Basic error handling if adding member fails
    if(!$AddMember){
        Write-Host "STEP 2c / 4) FAILED TO ADD $targetUser TO $SafeName...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
    else{
        Write-Host "STEP 2c / 4) SUCCESSFULLY ADDED $targetUser TO SAFE $SafeName" -ForegroundColor Green
    }
}
else{
    Write-Host "STEP 2c / 4) $targetUser ALREADY EXISTS AS A SAFE MEMBER...SKIPPING SAFE MEMBER ADDITION" -ForegroundColor DarkYellow
}

#SafeManager Section
#Query if SafeManager exists on the safe already
$DoesMemberExist = Get-VPASSafeMemberSearch -safe $SafeName -member "SafeManager"
if(!$DoesMemberExist){
    #This means that SafeManager is not found on the safe, lets add it with List, Manage safe, Manage Safe Members, View Audit Log, and View safe members permissions
    $AddMember = Add-VPASSafeMember -member "SafeManager" -safe $SafeName -MemberType Group -searchin vman.com -ListAccounts -ManageSafe -ViewAuditLog -ViewSafeMembers

    #Basic error handling if adding member fails
    if(!$AddMember){
        Write-Host "STEP 2d / 4) FAILED TO ADD SafeManager TO $SafeName...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
    else{
        Write-Host "STEP 2d / 4) SUCCESSFULLY ADDED SafeManager TO SAFE $SafeName" -ForegroundColor Green
    }
}
else{
    Write-Host "STEP 2d / 4) SafeManager ALREADY EXISTS AS A SAFE MEMBER...SKIPPING SAFE MEMBER ADDITION" -ForegroundColor DarkYellow
}

#Just an fyi, in PrivilegeCloud environments, you can also add Roles as safe members (similar to groups), just change the -MemberType value to Roles and -Searchin value to Vault

#At this point, a safe was created and the safe members have been added. Now lets handle onboarding the account and reconciling it
#In this example the following parameters will be set
#    SafeName: pSafe-vman-{targetUser} (what we created prior)
#    Username: adm-{targetUser}
#    PlatformID: WIN-DOM-7DAY-OTP-SUN
#    Address: vman.com
#    LogonTo: vman


#Query if the account exists already so we do not double onboard the account
$DoesAcctExist = Get-VPASAccountDetails -safe $SafeName -platform "WIN-DOM-7DAY-OTP-SUN" -username "adm-$targetUser" -address "vman.com" -ExactMatch
if(!$DoesAcctExist){
    #This means the account does not exist, lets onboard it
    $AddAccount = Add-VPASAccount -platformID "WIN-DOM-7DAY-OTP-SUN" -safeName $SafeName -address "vman.com" -username "adm-$targetUser" -extraProps @{LogonDomain="vman.com"}

    #Basic error handling if adding the account has failed
    if(!$AddAccount){
        Write-Host "STEP 3 / 4) FAILED TO ADD ACCOUNT adm-$targetUser...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
    else{
        Write-Host "STEP 3 / 4) SUCCESSFULLY CREATED ACCOUNT adm-$targetUser" -ForegroundColor Green
    }

    #After the account is created, we want to reconcile it
    $AcctID = $AddAccount.id
    $triggerReconcile = Invoke-VPASAccountPasswordAction -action Reconcile -AcctID $AcctID

    #Basic error handling if triggering reconcile has failed
    if(!$triggerReconcile){
        Write-Host "STEP 4 / 4) FAILED TO TRIGGER RECONCILE ON ACCOUNT adm-$targetUser...EXITING SCRIPT" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
    else{
        Write-Host "STEP 4 / 4) SUCCESSFULLY TRIGGERED RECONCILE ON ACCOUNT adm-$targetUser" -ForegroundColor Green
    }
}
else{
    Write-Host "STEP 3 / 4) adm-$targetUser ALREADY EXISTS...SKIPPING ACCOUNT CREATION" -ForegroundColor DarkYellow
    #The account was already onboarded prior, basic check to see if only one record showes up and to reconcile it
    if($DoesAcctExist.count -eq 1){
        $AcctID = $DoesAcctExist.value.id
        $triggerReconcile = Invoke-VPASAccountPasswordAction -action Reconcile -AcctID $AcctID

        #Basic error handling if triggering reconcile has failed
        if(!$triggerReconcile){
            Write-Host "STEP 4 / 4) FAILED TO TRIGGER RECONCILE ON ACCOUNT adm-$targetUser...EXITING SCRIPT" -ForegroundColor Red
            Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
            return $false
        }
        else{
            Write-Host "STEP 4 / 4) SUCCESSFULLY TRIGGERED RECONCILE ON ACCOUNT adm-$targetUser" -ForegroundColor Green
        }
    }
    else{
        #More then one record was returned, so we do not know what account is supposed to be the correct one. To avoid any issues we will leave the accounts alone and print out a message
        Write-Host "STEP 4 / 4) TOO MANY ACCOUNTS WERE RETURNED WITH A `nUSERNAME = adm-$targetUser`nSAFE = $SafeName`nPLATFORM = WIN-DOM-7DAY-OTP-SUN`nADDRESS = vman.com" -ForegroundColor Red
        Write-Host "SKIPPING RECONCILE STEP...RETURNING FALSE" -ForegroundColor Red
        Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
        return $false
    }
}

Write-Host "=== END PROCESS ===" -ForegroundColor Cyan
return $true


