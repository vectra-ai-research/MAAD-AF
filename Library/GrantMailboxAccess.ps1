function GrantMailboxAccess{
    mitre_details("GrantMailboxAccess")
    
    #Get mailbox to target
    EnterMailbox("`n[?] Enter mailbox to grant permissions of")
    $target_mailbox = $global:mailbox_address

    #Get recipient mailbox
    EnterMailbox("`n[?] Enter user to grant mailbox permissions to")
    
    $recipient_mailbox = $global:mailbox_address

    #Get current permissions on Mailbox
    Write-Host ""
    MAADWriteProcess "Fetching current mailbox permissions"
    $current_mb_perm = Get-MailboxPermission -Identity $target_mailbox
    MAADWriteProcess "Current permissions on mailbox -> $($current_mb_perm.Count) Users"
    $user_count = 1
    foreach ($user in $current_mb_perm){
        MAADWriteProcess "User $user_count : $($user.User) -> $($user.AccessRights)"
        $user_count += 1
    }

    MAADWriteProcess "Attempting permissions grant to mailbox"
    MAADWriteProcess "Config: User($recipient_mailbox) -> FullAccess -> Mailbox($target_mailbox)"
    
    ###Attempt to add mailbox permissions
    try {
        Add-MailboxPermission -Identity $target_mailbox -user $recipient_mailbox -AccessRights FullAccess | Out-Null
        MAADWriteProcess "Mailbox permissions granted to user"
        $allow_undo = $true

        #Get current permissions on Mailbox
        Write-Host ""
        MAADWriteProcess "Fetching updated mailbox permissions"
        $updated_mb_perm = Get-MailboxPermission -Identity $target_mailbox
        MAADWriteProcess "Updated permissions on mailbox -> $($updated_mb_perm.Count) Users"
        $user_count = 1
        foreach ($user in $updated_mb_perm){
            MAADWriteProcess "User $user_count : $($user.User) -> $($user.AccessRights)"
            $user_count += 1
        }
        MAADWriteSuccess "Mailbox Permission Granted"
    }
    catch {
        MAADWriteError "Failed to grant mailbox permission"
    }

    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Remove mailbox permissions (y/n)"
        Write-Host ""
        if ($user_confirm -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Removing mailbox permissions grant for $recipient_mailbox"
                Remove-MailboxPermission -Identity $target_mailbox -User $recipient_mailbox -AccessRights FullAccess -Confirm:$false | Out-Null
                MAADWriteProcess "Mailbox permission removed"
                try {
                    #Get current permissions on Mailbox
                    Write-Host ""
                    MAADWriteProcess "Fetching updated mailbox permissions"
                    $updated_mb_perm = Get-MailboxPermission -Identity $target_mailbox
                    MAADWriteProcess "Updated permissions on mailbox -> $($updated_mb_perm.Count) Users"
                    $user_count = 1
                    foreach ($user in $updated_mb_perm){
                        MAADWriteProcess "User $user_count : $($user.User) -> $($user.AccessRights)"
                        $user_count += 1
                    }
                }
                catch {
                    MAADWriteError "Failed to fetch updated mailbox permissions"
                }
                MAADWriteSuccess "Removed Mailbox Permission"
            }
            catch {
                MAADWriteError "Failed to remove mailbox permission"
            }
        }
    }
    MAADPause
}