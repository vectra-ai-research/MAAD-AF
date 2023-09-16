#Reconnaissance modules

function MAADGetAllAADUsers ($download = $false){
    #Search all accounts
    try {
        $all_accounts = Get-AzureADUser -All $true 
        
        #Check if output is too large
        if ($download -eq $true){
            Write-Host "`nDownloading all accounts list from tenant" -ForegroundColor Gray
            $all_accounts | Out-File -FilePath .\Outputs\All_Accounts.txt -Append
            Write-Host "`nAccounts list dumped to: /Outputs/All_Accounts.txt" -ForegroundColor Yellow
        }
        else{
            Write-Host "`nSearching accounts in tenant..." -ForegroundColor Gray
            if ($all_accounts.Count -gt 20){
                $user_input = Read-Host "`nFound $($all_accounts.Count) accounts in tenant. Display them all (Y/N(default))"
                if ($user_input -eq "y"){
                    $all_accounts | Format-Table -Property DisplayName, UserPrincipalName, ObjectID,UserType -Wrap -RepeatHeader | more
                }
                else{
                    Write-Host "`nDownloading accounts list from tenant" -ForegroundColor Gray
                    $all_accounts | Out-File -FilePath .\Outputs\All_Accounts.txt -Append
                    Write-Host "`nAccounts list dumped to: /Outputs/All_Accounts.txt" -ForegroundColor Yellow
                }
            }
            else{
                $all_accounts | Format-Table -Property DisplayName, UserPrincipalName, ObjectID,UserType -Wrap -RepeatHeader | more
            }
        }
    }
    catch {
        Write-Host "[Error] Could not search accounts in tenant" -ForegroundColor Red
    }
}

function MAADGetAllAADGroups {
    #Search all groups
    try {
        Write-Host "Searching groups in tenant..." -ForegroundColor Gray
        $all_groups = Get-AzureADGroup -All $true  
        
        #Check if output is too large
        if ($all_groups.Count -gt 20){
            $user_input = Read-Host "Found $($all_groups.Count) accounts in tenant. Display them all (Y/N(default))"
            if ($user_input -eq "y"){
                $all_groups | Format-Table -Wrap | more
            }
            else{
                Write-Host "`nDownloading groups list from tenant" -ForegroundColor Gray
                $all_groups | Out-File -FilePath .\Outputs\All_Groups.txt -Append
                Write-Host "`nAccounts list dumped to: /Outputs/All_Groups.txt" -ForegroundColor Yellow
            }
        }
        else{
            $all_groups | Format-Table -Wrap | more
        }
    }
    catch {
        Write-Host "[Error] Could not search groups in tenant" -ForegroundColor Red
    }
}

function MAADGetAllMailboxes ($download = $false){
    #List all accounts
    try {
        $all_mailboxes = Get-Mailbox 
        if ($download -eq $true){
            Write-Host "`nDownloading mailbox list from tenant" -ForegroundColor Gray
            $all_mailboxes | Out-File -FilePath .\Outputs\All_Mailboxes.txt -Append
            Write-Host "`nMailbox list dumped to: /Outputs/All_Mailboxes.txt" -ForegroundColor Yellow
        }
        else{
            Write-Host "`nSearching mailoxes in tenant..." -ForegroundColor Gray
            $all_mailboxes | Format-Table -Property DisplayName,PrimarySmtpAddress | more
        }
    }
    catch {
        Write-Host "`n[Error] Could not list accounts in tenant" -ForegroundColor Red
    }
}

function MAADGetAllServicePrincipal {
    #List all service principaals
    try {
        Write-Host "`nListing service principals in tenant..." -ForegroundColor Gray
        Get-AzureADServicePrincipal | Format-Table DisplayName, AppId, ObjectId -Wrap | more
    }
    catch {
        Write-Host "`n[Error] Could not list service principals in tenant" -ForegroundColor Red
    }
}

function ListAuthorizationPolicy {
    #List all authorization policies
    try {
        Write-Host "`nListing authorization policies in tenant..." -ForegroundColor Gray
        Get-AzureADMSAuthorizationPolicy | Format-Table | more
    }
    catch {
        Write-Host "`n[Error] Could not list authorization policies in tenant" -ForegroundColor Red
    }
}

function MAADGetNamedLocations {
    #List all named locations
    try {
        Write-Host "`nListing named locations in tenant..." -ForegroundColor Gray
        Get-AzureADMSNamedLocationPolicy | Format-Table DisplayName, IsTrusted, IpRanges, CountriesAndRegions -Wrap | more
    }
    catch {
        Write-Host "`n[Error] Could not list named locations in tenant" -ForegroundColor Red
    }
}

function MAADGetConditionalAccessPolicies {
    try {
        #Get conditional access policies
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
    catch {
        Write-Host "`n[Error] Could not retrieve conditional access policies in tenant" -ForegroundColor Red
    }
}

function MAADGetRegisteredDevices {
    #List all user's registered devices
    try {
        Write-Host "`nListing registered devices for account..." -ForegroundColor Gray
        $target_account = Read-Host -Prompt "Enter a user account to retrieve its registered devices"
        Get-AzureADUserRegisteredDevice -ObjectId $target_account | Format-Table -Wrap | more
    }
    catch {
        Write-Host "`n[Error] Could not list registered devices for account" -ForegroundColor Red
    }
}

function MAADGetAccessibleTenants {
    #List all accessible tenants
    try {
        Write-Host "Listing all accessible tenant..." -ForegroundColor Gray
        Get-AzTenant | Format-Table
    }
    catch {
        Write-Host "`n[Error] Could not list accessible tenant" -ForegroundColor Red
    }
}

function MAADGetAllSharepointSites ($teams_connected = $false){
    #List all accessible sites in tenants
    try {
        if ($teams_connected -eq $true){
            Write-Host "`nSearching for teams connected SharePoint sites in tenant..." -ForegroundColor Gray
            $all_sites = Get-SPOSite | ?{$_.IsTeamsConnected -eq $true}
        }
        else{
            Write-Host "`nSearching for all SharePoint sites in tenant..." -ForegroundColor Gray 
            $all_sites = Get-SPOSite 
            
        }
        $all_sites
        Write-Host "`nFound $($all_sites.Count) sites in tenant." -ForegroundColor Gray
        $all_sites | Format-Table -Property Title,URL,SharingCapability | more
    }
    catch {
        Write-Host "`n[Error] Could not find SharePoint sites in tenant" -ForegroundColor Red
    }
}

function MAADGetAllTeams{
    #List all teams tenants
    try {
        Write-Host "`nSearching for all Teams sites in tenant..." -ForegroundColor Gray
        $all_teams = Get-Team 
        $all_teams  | Format-Table  DisplayName,GroupID,Description,Visibility -RepeatHeader| more
    }
    catch {
        Write-Host "`n[Error] Could not find Teams in tenant" -ForegroundColor Red
    }
}

function MAADGetAccountGroupRoles {
    #Get all group roles in Azure AD
     $all_roles = Get-AzureADDirectoryRole
 
     #Get target account
     EnterAccount ("Select an account to recon group roles")
     $target_account = $global:account_username
     
     $user_roles = @()
 
     Write-Host "`nEnumerating through user group roles ..."
 
     foreach ($role in $all_roles){
         $role_object_id = $role.ObjectId
         if ($target_account -in (Get-AzureADDirectoryRoleMember -ObjectId $role_object_id).UserPrincipalName) {
             #Write-Host "User has role: $($role.DisplayName)"
             $user_roles += $role.DisplayName
         }
     }
 
     Write-Host "`nFollowing role groups were found for user $target_account :" -ForegroundColor Gray
     $user_roles
 
     Write-Host "`nUser has: $($user_roles.Count)/$($all_roles.Count)`n" 
 }