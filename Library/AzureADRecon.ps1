function AzureADRecon {
   
   $recon_options = @{0 = "Back to main menu"; 1 = "Retrieve Current Session Information"; 2 = "Grab Azure Access Token"; 3 = "Enumerate accounts group roles"; 4 = "Retrieve Domain Information"; 5 = "Retrieve All Users in Domain"; 6 = "Retrieve all Groups in Domain"; 7 = "Retrieve AD Authorization Policy"; 8 = "Retrieve Named Location Policies"; 9 = "Get AzureAD Conditional Access Policies"; 10 = "Retrieve Users Registered Device"; 11 = "Retrieve Service Principal Information"; 12 = "List Administrator Roles"; 13 = "List Accessible Tenants"};

   do {
      OptionDisplay "Recon Options:" $recon_options

      while ($true) {
         try {
               Write-Host "`n"
               [int]$recon_user_choice = Read-Host -Prompt 'Choose a recon option:'
               break
         }
         catch {
               Write-Host "Invalid input!!! Choose an option number from the list!"
         }
      }
      
      if ($recon_user_choice -eq 1) {
         #Get current session info
         Get-AzureADCurrentSessionInfo | Format-Table -Wrap
      }

      if ($recon_user_choice -eq 2) {
         #Get current user access token

         #Display options to generate different types of tokens
         $token_types = @("AadGraph", "AnalysisServices", "AppConfiguration", "Arm", "Attestation", "Batch", "DataLake", "KeyVault", "MSGraph", "OperationalInsights", "ResourceManager", "Storage", "Synapse")
         foreach ($item in $token_types){
            Write-Host $token_types.IndexOf($item) ":" $item -ForegroundColor Gray
         }
         [int]$token_type_choice = Read-Host "`nChoose a token type to generate"
         $token_type = $token_types[$token_type_choice]
         #Generate token
         try {
            $token = Get-AzAccessToken -ResourceTypeName $token_type
            $token | Out-Host
            #Saved token information to tokens file
            "Token type: $token_type" | Out-File -Append -FilePath .\Outputs\Azure_AD_Tokens.txt
            $token | Out-File -Append -FilePath .\Outputs\Azure_AD_Tokens.txt
            Write-Host "Token saved to Outputs directory" -ForegroundColor Gray
         }
         catch {
            Write-Host "Failed to generate token!" -ForegroundColor Red
         }
      }

      if ($recon_user_choice -eq 3) {
         #Get user's group roles
         ReconUserGroupRoles
      }

      if ($recon_user_choice -eq 4) {
         #Get Domain Details
         Get-AzureADDomain | Format-Table -Wrap
      }

      if ($recon_user_choice -eq 5) {
         #Get all users
         Get-AzureADUser -All $true |Format-Table DisplayName, UserPrincipalName, ObjectID,UserType -Wrap
      }

      if ($recon_user_choice -eq 6) {
         #Get Azure AD Groups
         Get-AzureADGroup | Format-Table -Wrap
      }

      if ($recon_user_choice -eq 7) {
         #Gets an authorization policy, which represents a policy that can control Azure Active Directory authorization settings.
         Get-AzureADMSAuthorizationPolicy | Format-Table
      }

      if ($recon_user_choice -eq 8) {
         #Get named locations
         Get-AzureADMSNamedLocationPolicy | Format-Table DisplayName, IsTrusted, IpRanges, CountriesAndRegions -Wrap
      }

      if ($recon_user_choice -eq 9) {
         #Get a user's registered device
         Get-AzureADMSConditionalAccessPolicy | Format-Table DisplayName, Id, State
         Write-Host "`nShowing detailed information on each policy below...`n" -ForegroundColor Gray
         Start-Sleep -Seconds 5

         $conditional_policy_list = Get-AzureADMSConditionalAccessPolicy
         foreach ($policy in $conditional_policy_list){
               Write-Host "`n###########################################" 
               Write-Host "Policy Name:" -ForegroundColor Yellow
               $policy.DisplayName
               Write-Host "###########################################" 
               Write-Host "`nPolicy state:"
               $policy.State
               Write-Host "`nPolicy ID:"
               $policy.Id
               Write-Host "`nPolicy Conditions:`n"
               #$policy.Conditions | Format-Table
               $policy.Conditions.Applications | Format-Table
               $policy.Conditions.Users | Format-Table
               $policy.Conditions.Platforms| Format-Table
               $policy.Conditions.Locations| Format-Table
               $policy.Conditions.SignInRiskLevels| Format-Table
               $policy.Conditions.ClientAppTypes| Format-Table
         }  
      }

      if ($recon_user_choice -eq 10) {
         #Get a user's registered device
         $recon_user = Read-Host -Prompt "Enter a user account to retrieve its registered devices"
         Get-AzureADUserRegisteredDevice -ObjectId $recon_user | Format-Table -Wrap
      }

      if ($recon_user_choice -eq 11) {
         #Gets service principal info
         Get-AzureADServicePrincipal | Format-Table DisplayName, AppId, ObjectId -Wrap
      }

      if ($recon_user_choice -eq 12) {
         #Gets Administrator roles
         Get-MsolRole | Format-Table
      }

      if ($recon_user_choice -eq 13) {
         #List accessible tenants
         Get-AzTenant | Format-Table
      }

   } while (
      $recon_user_choice -ne 0)
        
}