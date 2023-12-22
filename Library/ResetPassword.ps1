function ResetPassword {

    mitre_details("ResetPassword")

    MAADWriteInfo "Results of this action cannot be reversed"

    EnterAccount "`n[?] Enter user to reset password for (user@org.com)"
    $target_account = $global:account_username

    $new_password = Read-Host -Prompt "`n[?] Enter new password to set (must comply with password policy)"
    Write-Host ""
    $new_secure_password = ConvertTo-SecureString $new_password -AsPlainText -Force 
    $output_path = ".\Outputs\PasswordResets.txt"

    #Reset password
    try {
        MAADWriteProcess "Resetting account password"
        Set-AzureADUserPassword -ObjectId $target_account -Password $new_secure_password -EnforceChangePasswordPolicy $false -ErrorAction Stop
        Start-Sleep -s 5 
        "User: $target_account | NewPassword: $new_password" | Out-File -FilePath $output_path -Append
        MAADWriteProcess "Output Saved -> \MAAD-AF\Outputs\PasswordResets.txt"
        
        #Save to credential store
        AddCredentials "password" "RP_$target_account-$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $target_account $new_password

        MAADWriteSuccess "Password reset successful"
    }
    catch {
        MAADWriteError "Failed to reset password"
    }
    MAADPause
}