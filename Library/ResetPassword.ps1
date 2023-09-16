function ResetPassword {

    mitre_details("ResetPassword")

    Write-Warning "Results of this action cannot be reversed!!!"

    EnterAccount ("`nEnter an account to reset password for (user@org.com)")
    $target_account = $global:account_username

    $new_password = Read-Host -Prompt "Enter new password to set (must comply with password policy)"
    $new_secure_password = ConvertTo-SecureString $new_password -AsPlainText -Force 

    #Reset password
    try {
        Write-Host "`nResetting password...`n" -ForegroundColor Gray
        Set-AzureADUserPassword -ObjectId $target_account -Password $new_secure_password -EnforceChangePasswordPolicy $false -ErrorAction Stop
        Start-Sleep -s 5 
        "User: $target_account | NewPassword: $new_password" | Out-File -FilePath .\Outputs\PasswordResets.txt -Append
        Write-Host "`nUser: $target_account`nNew Password: $new_password"
        Write-Host "`n[Success] Password reset for $target_account" -ForegroundColor Yellow

        #Save to credential store
        AddCredentials "password" "RP_$target_account-$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $target_account $new_password
    }
    catch {
        Write-Host "`n[Error] Failed to reset password for $target_account" -ForegroundColor Red
    }
}