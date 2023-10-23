function DisableMFA {

    mitre_details("DisableMFA")

    EnterAccount ("Enter an account to disable MFA for (user@org.com)")
    $target_account = $global:account_username

    #Disabe MFA
    try {
        Write-Host "`nDisabling MFA for the account ..."
        Get-MsolUser -UserPrincipalName $target_account | Set-MsolUser -StrongAuthenticationRequirements @() -ErrorAction Stop
        Start-Sleep -s 5 
        Write-Host "`n[Success] Guards Down - MFA disabled for $target_account" -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to disable MFA for $target_account" -ForegroundColor Red
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        #Enable MFA
        $user_choice = Read-Host -Prompt "`nWould you like to re-enable MFA for the account? (yes/no)"

        if ($user_choice -notin "No","no","N","n") {
            Write-Host "`nEnabling MFA for account $target_account ..." -ForegroundColor Gray
            $mfa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
            $mfa.RelyingParty = "*"
            $mfa.State = "Enabled"
            $mfax = @($mfa)
            try {
                Set-MsolUser -UserPrincipalName $target_account -StrongAuthenticationRequirements $mfax
                Write-Host "`n[Undo Success] Re-enabled MFA for account $target_account" -ForegroundColor Yellow
            }
            catch {
                Write-Host "`n[Undo Error] Failed to enable MFA for the account $target_account. Try enabling through Admin console" -ForegroundColor Red
            }
        }
    }
    Pause
}