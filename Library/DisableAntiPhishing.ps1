function DisableAntiPhishing {

    mitre_details("DisableAntiPhishing")

    #List all AntiPhish Policy
    $inititate_recon = Read-Host -Prompt "`n[?] Initiate recon to retrive all AntiPhishing policies (y/n)"
    Write-Host ""
    
    if ($inititate_recon -notin "No","no","N","n"){
        MAADWriteProcess "Finding Anti-Phishing policies in tenant"
        Get-AntiPhishRule | Format-Table Name,State,Priority,Identity
    }
    else {
        #DoNothing
    }

    #Select a policy to modify
    $policy_name = Read-Host -Prompt "`n[?] Enter AntPhishing policy from table to disable"
    Write-Host ""

    try {
        MAADWriteProcess "Fetching policy current status"
        $policy_current_status = Get-AntiPhishRule -Identity $policy_name
        MAADWriteProcess "$($policy_current_status.Name) -> $($policy_current_status.State)"
    }
    catch {
        MAADWriteError "Failed to fetch policy status"
    }

    #Disable AntiPhishing policy
    try {
        MAADWriteProcess "Disabling anti-phishing policy -> $policy_name"
        Disable-AntiPhishRule -Identity $policy_name -Confirm:$false -ErrorAction Stop | Out-Null
        Start-Sleep -s 5
        MAADWriteProcess "Fetching updated policy status"
        $policy_updated_status = Get-AntiPhishRule -Identity $policy_name
        MAADWriteProcess "$($policy_updated_status.Name) -> $($policy_updated_status.State)"
        MAADWriteSuccess "Disabled Anti-phishing Policy"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to disable anti-phishing policy"
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        #Re-enble AntiPhishing Policy
        $user_choice = Read-Host -Prompt "`n[?] Undo: Re-enable Anti-Phishing policy (y/n)"
        Write-Host ""

        if ($user_choice -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Enabling anti-phishing policy -> $policy_name"
                Enable-AntiPhishRule -Identity $policy_name -Confirm:$false | Out-Null
                Start-Sleep -s 5 
                $policy_updated_status = Get-AntiPhishRule -Identity $policy_name
                MAADWriteProcess "$($policy_updated_status.Name) -> $($policy_updated_status.State)"
                MAADWriteSuccess "Re-enabled Anti-phishing Policy"
            }
            catch {
                MAADWriteError "Failed to re-enable anti-phishing policy"
            }
        }
    }
    MAADPause
}