function DisableMFA {

    mitre_details("DisableMFA")

    EnterAccount ("Enter an account to disable MFA for (user@org.com)")
    $target_account = $global:input_user_account

    #Disabe MFA
    try {
        Write-Host "`nDisabling MFA for the account ..."
        Get-MsolUser -UserPrincipalName $target_account | Set-MsolUser -StrongAuthenticationRequirements @() -ErrorAction Stop
        Start-Sleep -s 5 
        Write-Host "`nGuards Down!!! MFA successfully disabled for $target_account" -ForegroundColor Yellow -BackgroundColor Black
        $allow_undo = $true
    }
    catch {
        Write-Host "`nError: Failed to disable MFA for $target_account"
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        #Enable MFA
        $user_choice = Read-Host -Prompt 'Would you like to re-enable MFA for the account? (yes/no)'

        if ($user_choice -notin "No","no","N","n") {
            Write-Host "`nEnabling MFA for account $target_account ..."
            $mfa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
            $mfa.RelyingParty = "*"
            $mfa.State = "Enabled"
            $mfax = @($mfa)
            try {
                Set-MsolUser -UserPrincipalName $target_account -StrongAuthenticationRequirements $mfax
                Write-Host "Undo successful: Re-enabled MFA for account $target_account!" -ForegroundColor Yellow -BackgroundColor Black
            }
            catch {
                Write-Host "Error: Failed to enable MFA for the account $target_account. Try enabling through Admin console."
            }
        }
    }
    Pause
}