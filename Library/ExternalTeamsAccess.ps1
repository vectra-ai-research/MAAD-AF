function ExternalTeamsAccess {
    
    mitre_details("ExternalTeamsAccess")

    while ($true) {
        $module_choice = Read-Host -Prompt "`nWould you like to `n 1. Get added to an existing team `n 2. Create a new Team and get added to it `n (Note: Option 2 will automatically create a new Team in Teams)`n"    

        if ($module_choice -eq 1) {
            $user_choice = Read-Host -Prompt "Would you like to initiate recon to find available teams? (yes/no)"
            if ($user_choice -notin "No","no","N","n") {
                Write-Host "`nRecon: Searching information on available teams in the environment ..." @fg_yellow
                Get-Team | Format-Table DisplayName,GroupID,Description,Visibility    
            }
            
            do {
                $repeat = $true
                $display_name = Read-Host -Prompt "Enter the 'Display Name' of the existing team you would like to get added to"
                
                #Check if team exists
                $test_valid = Get-Team -DisplayName $display_name
                if ($test_valid -eq $null) {
                    Write-Warning "`nThe team entered does not exist. Please provide a valid team name."
                    Write-Host "Available teams:"
                    Get-Team | Format-Table DisplayName,GroupID,Description,Visibility
                }

                else {
                    Write-Host "Found Team $display_name!!!"
                    $repeat = $false
                }
            } while ($repeat -eq $true)
                
            break
        }
        
        if ($module_choice -eq 2) {
            #Create a new team
            $display_name = Read-Host -Prompt 'Enter a cool name to create your new team'
            Write-Host "`nCreating a new Team ..."
            New-Team -DisplayName $display_name -Description "New team to test detections" -Visibility Private 
            Start-Sleep -Seconds 10
            break
        }
    }

    #Create External Account
    try {
        #Attemp inviting account. This will automatically fail and the rest of the module will continue as intended if the account being added is an internal account. 
        #If the account being added is an external account then the account will be invited and the rest of the module will continue.
        $external_email_address = Read-Host -Prompt 'Enter an (external or internal) email account to grant access to Teams (eg: external@domain.com)'
        New-AzureADMSInvitation -InvitedUserDisplayName "APT-$external_email_address" -InvitedUserEmailAddress $external_email_address -InviteRedirectURL https://myapps.microsoft.com -SendInvitationMessage $true
    }
    catch {
        #Do nothing.
    }
    
    #Retrieve available teams group ID
    $team_details = Get-Team -DisplayName $display_name 
    $group_id = $team_details.GroupId

    Write-Warning -Message "This configuration can sometimes take several minutes to take effect.`n"
    [int]$time_limit_min = (Read-Host -Prompt "Set a limit on how long you would like to wait (minutes)")
    [int]$time_limit_sec = $time_limit_min*60
    Write-Host "`nIts been a long day of hacking things. Go grab youself some coffee!!! The tool is checking for config change...`n"

    #Add to teams group 
    [int]$timer = 0
    while ($timer -le $time_limit_sec){
        try{
            Add-TeamUser -GroupId $group_id -Role Member -User $external_email_address -ErrorAction Stop
            Write-Host "Successfully added new account: $external_email_address to teams group: $display_name" @fg_yellow @bg_black
            $allow_undo = $true
            break
        }
        catch{
            Write-Output "Account hasn't replicated - Attempting again in 60 seconds"
            Start-sleep -Seconds 60
            $timer = $timer+60
            Write-Host "Time remaining: $(($time_limit_sec - $timer)/60) minutes"
        }
    } 

    #Undo changes
    if ($allow_undo -eq $true) {
        $user_choice = Read-Host -Prompt 'Would you like to undo changes made in teams? (yes/no)'
        if ($user_choice -notin "No","no","N","n") {
            if ($module_choice -eq 1) {
                Write-Host "`nRemoving new user from team $display_name ..."
                try {
                    Remove-TeamUser -GroupId $group_id -User $external_email_address -ErrorAction Stop
                    Write-Host "`nUndo successful: Removed new user: $external_email_address from team: $display_name"
                }
                catch {
                    Write-Host "`nError: Failed to remove new user $external_email_address from team $display_name. Try removing user manually from Admin console."
                } 
            }
            elseif ($module_choice -eq 2) {
                Write-Host "`nRemoving new user: $external_email_address and deleting the Team:  $display_name ..."
                try {
                    Remove-TeamUser -GroupId $group_id -User $external_email_address -ErrorAction Stop
                    Remove-Team -GroupId $group_id -ErrorAction Stop
                    Write-Host "`nUndo successful: Removed new user: $external_email_address and deleted team: $display_name"
                }
                catch {
                    Write-Host "`nError: Failed to remove new user: $external_email_address and delete team: $display_name. Try removing user manually from Admin console."
                } 
            }
        }
    }
    Pause
}
