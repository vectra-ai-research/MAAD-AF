#Create New Group

function CreateNewAzureADGroup {
    $new_group_display_name = Read-Host -Prompt "`n[?] Enter name to create new group"
    $new_group_description = Read-Host -Prompt "`n[?] Enter description for new group (leave blank and press [enter] for default description)"
    Write-Host ""

    #If no description provided by user, set default description
    if ($null -eq $new_group_description -or "" -eq $new_group_description) {
        $new_group_description = "MAAD-AF Azure AD Group"
    }

    #Create the group with set parameters
    try {
        MAADWriteProcess "Attempting to create new Group -> $new_group_display_name"
        $new_group = New-AzureADGroup -DisplayName $new_group_display_name -Description $new_group_description -MailEnabled $false -SecurityEnabled $true -ErrorAction Stop
        Start-Sleep -Seconds 10
        MAADWriteSuccess "New Group Created"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to create new group"
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Delete the new group (y/n)"
        Write-Host ""
        if ($user_confirm -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Attempting to delete new Group -> $new_group_display_name"
                $group_details = Get-AzureADGroup -SearchString $new_group_display_name
                $group_id = $group_details.ObjectId
                Remove-AzureADGroup -ObjectId $group_id -ErrorAction Stop | Out-Null
                MAADWriteSuccess "New Group Deleted"
            }
            catch {
                MAADWriteError "Could not delete new group"
            }
        }
    }
    MAADPause
}


function CreateNewM365Group{
    [string]$new_group_display_name = Read-Host -Prompt "`n[?] Enter name to create new group"

    #Create the group with set parameters
    try {
        MAADWriteProcess "Creating a new Group -> $new_group_display_name"
        $new_group = New-UnifiedGroup -DisplayName $new_group_display_name -AccessType Public -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 10
        MAADWriteSuccess "New Group Created"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to create new group"
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Delete the new group (y/n)"
        Write-Host ""
        if ($user_confirm -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Attempting to delete new Group -> $new_group_display_name"
                Remove-UnifiedGroup -Identity $new_group_display_name -Force -Confirm:$false -ErrorAction Stop | Out-Null
                MAADWriteSuccess "New Group Deleted"
            }
            catch {
                MAADWriteError "Could not delete new group"
            }
        }
    }
    MAADPause
}

