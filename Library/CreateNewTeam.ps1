#Create new team

function CreateNewTeam{
    #Get new team name and description from user
    $new_team_display_name = Read-Host -Prompt "`n[?] Enter name to create new team"
    $new_team_description = Read-Host -Prompt "`n[?] Enter description for new team (leave blank and press [enter] for default description)"
    
    #If no description provided by user, set default description
    if ($null -eq $new_team_description -or "" -eq $new_team_description) {
        $new_team_description = "MAAD-AF Team"
    }

    #Create the team with set parameters
    try {
        MAADWriteProcess "Creating a new Team"
        $new_team = New-Team -DisplayName $new_team_display_name -Description [string]$new_team_description -Visibility Private -ErrorAction Stop
        Start-Sleep -Seconds 10
        MAADWriteSuccess "New Team Created"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to create new team"
    }
   
    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Delete the new team (y/n)"

        if ($user_confirm -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Deleting new team -> $new_team_display_name"
                $team_details = Get-Team -DisplayName $new_team_display_name 
                $team_id = $team_details.GroupId
                Remove-Team -GroupId $team_id -ErrorAction Stop
                MAADWriteSuccess "New Team Deleted"
            }
            catch {
                MAADWriteError "Failed to delete new team"
            }
        }
    }
    MAADPause
}