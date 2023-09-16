#Add user to group
function AddObjectToGroup {

    mitre_details("AddObjectToGroup")

    EnterAccount ("Select an account to add to group (user@org.com)")
    $target_account = $global:account_username
    $target_account_id = (Get-AzureADUser -SearchString $target_account).ObjectId

    EnterGroup("Enter a target group name to add the account to (Leave blank and press enter to recon all groups)")
    $target_group = $global:group_name
    $target_group_id = (Get-AzureADMSGroup -SearchString $target_group).Id

    #Add account to group
    try {
        Write-Host "`nAdding account to group..." -ForegroundColor Gray
        Add-AzureADGroupMember -ObjectId $target_group_id -RefObjectId $target_account_id -ErrorAction Stop
        Start-Sleep -s 5
        Write-Host "`n[Success] added account: $target_account to group: $target_group" -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to add account to group $target_group" -ForegroundColor Red
    }

    if ($allow_undo -eq $true) {
        #Remove user from Group
        $user_choice = Read-Host -Prompt "Would you like to undo actions by removing account from the group? (yes/no)"
        if ($user_choice -notin "No","no","N","n") {
            try {
                Write-Host "`nRemoving account $target_account from group: $target_group..."
                Remove-AzureADGroupMember -ObjectId $target_group_id -MemberId $target_account_id -ErrorAction Stop
                Start-Sleep -s 5
                Write-Host "`n[Success] Removed account: $target_account from group: $target_group" -ForegroundColor Yellow
            }
            catch {
                Write-Host "[Error] Failed to remove account from the group. Try removing through Admin console." -ForegroundColor Red
            }
        }
    }
}