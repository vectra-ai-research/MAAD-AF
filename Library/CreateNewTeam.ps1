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
        Write-Host "Successfully created new team!" -BackgroundColor Black -ForegroundColor Gray
        $allow_undo = $true
    }
    catch {
        Write-Host "Error: Failed to create new team" -ForegroundColor Red
    }
   
    #Undo changes
    if ($allow_undo -eq $true) {
        try {
            $team_details = Get-Team -DisplayName $new_team_display_name 
            $team_id = $team_details.GroupId
            Remove-Team -GroupId $team_id -ErrorAction Stop
            Write-Host "`nUndo successful: Deleted new team: $new_team_display_name" -ForegroundColor Yellow
        }
        catch {
            Write-Host "`nUndo failed: Could not delete new team: $new_team_display_name" -BackgroundColor Red
        }
    }
    Pause
}