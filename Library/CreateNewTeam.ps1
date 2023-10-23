#Create new team

function CreateNewTeam{
    #Get new team name and description from user
    $new_team_display_name = Read-Host -Prompt 'Enter a cool name to create new team'
    $new_team_description = Read-Host -Prompt 'Enter a description for new team (leave blank and press enter for default description)'
    
    #If no description provided by user, set default description
    if ($null -eq $new_team_description -or "" -eq $new_team_description) {
        $new_team_description = "MAAD-AF Team"
    }

    #Create the team with set parameters
    try {
        Write-Host "`nCreating a new Team ..."
        $new_team = New-Team -DisplayName $new_team_display_name -Description [string]$new_team_description -Visibility Private -ErrorAction Stop
        Start-Sleep -Seconds 10
        Write-Host "`n[Success] Created new team" -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to create new team" -ForegroundColor Red
    }
   
    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`nWould you like to undo changes by deleting the new team? (yes/no)"

        if ($user_confirm -notin "No","no","N","n") {
            try {
                $team_details = Get-Team -DisplayName $new_team_display_name 
                $team_id = $team_details.GroupId
                Remove-Team -GroupId $team_id -ErrorAction Stop
                Write-Host "`n[Undo Success] Deleted new team: $new_team_display_name" -ForegroundColor Yellow
            }
            catch {
                Write-Host "`n[Undo Error] Failed to delete new team: $new_team_display_name" -BackgroundColor Red
            }
        }
    }
    Pause
}