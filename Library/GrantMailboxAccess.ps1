function GrantMailboxAccess{
    mitre_details("GrantMailboxAccess")
    
    #Get mailbox to target
    EnterMailbox("Enter target mailbox to grant access of")
    $target_mailbox = $global:input_mailbox_address

    #Get recipient mailbox
    EnterMailbox("Enter recipient mailbox to grant access to")
    $recipient_mailbox = $global:input_mailbox_address

    Write-Host "Attempting to grant $target_mailbox mailbox access to $recipient_mailbox"
    
    ###Attempt to add mailbox permissions
    try {
        Add-MailboxPermission -Identity $target_mailbox -user $recipient_mailbox -AccessRights FullAccess
        Write-Host "`nPermission grant succesful!"
        Write-Host "$recipient_mailbox has full access rights to $target_mailbox mailbox" @fg_yellow @bg_black
        $allow_undo = $true
    }
    catch {
        Write-Host "Failed to add mailbox permission" @fg_red
    }

    if ($allow_undo -eq $true) {
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt 'Would you like to undo modifications and remove mailbox access (yes/no)'
        if ($user_confirm -notin "No","no","N","n") {
            Write-Host "Removing mailbox access to: $target_mailbox ...`n"
            Remove-MailboxPermission -Identity $target_mailbox -User $recipient_mailbox -AccessRights FullAccess
            Write-Host "`nUndo successful: Removed mailbox access grant to $target_mailbox mailbox!!!" @fg_yellow @bg_black
        }
    }
    Pause
}