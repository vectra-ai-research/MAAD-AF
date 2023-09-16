function GrantMailboxAccess{
    mitre_details("GrantMailboxAccess")
    
    #Get mailbox to target
    EnterMailbox("Enter target mailbox to grant access of")
    $target_mailbox = $global:mailbox_address

    #Get recipient mailbox
    EnterMailbox("Enter recipient mailbox to grant access to")
    $recipient_mailbox = $global:mailbox_address

    Write-Host "Attempting to grant $target_mailbox mailbox access to $recipient_mailbox" -ForegroundColor Gray
    
    ###Attempt to add mailbox permissions
    try {
        Add-MailboxPermission -Identity $target_mailbox -user $recipient_mailbox -AccessRights FullAccess
        Write-Host "`n[Success] $target_mailbox mailbox permission granted to $recipient_mailbox!" -ForegroundColor Yellow
        Write-Host "$recipient_mailbox has full access rights to $target_mailbox mailbox" -ForegroundColor Gray
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to add mailbox permission" -ForegroundColor Red
    }

    if ($allow_undo -eq $true) {
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt 'Would you like to undo modifications and remove mailbox access (yes/no)'
        if ($user_confirm -notin "No","no","N","n") {
            Write-Host "Removing mailbox access to: $target_mailbox ...`n" -ForegroundColor Gray
            Remove-MailboxPermission -Identity $target_mailbox -User $recipient_mailbox -AccessRights FullAccess
            Write-Host "`n[Undo Success] Removed mailbox access grant to $target_mailbox mailbox!!!" -ForegroundColor Yellow
        }
    }
    Pause
}