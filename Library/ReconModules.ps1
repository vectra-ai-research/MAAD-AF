#Reconnaissance modules

function MAADGetAllAADUsers ($download = $false){
    #Search all accounts
    try {
        $all_accounts = Get-AzureADUser -All $true 
        
        #Check if output is too large
        if ($download -eq $true){
            Write-Host "[*] Downloading all accounts list from tenant" -ForegroundColor Gray
            $all_accounts | Out-File -FilePath .\Outputs\All_Accounts.txt -Append
            Write-Host "`[+] Accounts list dumped to: /Outputs/All_Accounts.txt" -ForegroundColor Yellow
        }
        else{
            Write-Host "[*] Searching accounts in tenant" -ForegroundColor Gray
            if ($all_accounts.Count -gt 20){
                Write-Host "[+]Found $($all_accounts.Count) accounts in tenant" -ForegroundColor Yellow
                $user_input = Read-Host "`n[?] Display all accounts (y/n)"
                if ($user_input -eq "y"){
                    $all_accounts | Format-Table -Property DisplayName, UserPrincipalName, ObjectID,UserType -Wrap -RepeatHeader | more
                }
                else{
                    Write-Host "[*] Exporting accounts list from tenant" -ForegroundColor Gray
                    $all_accounts | Out-File -FilePath .\Outputs\All_Accounts.txt -Append
                    Write-Host "[+] Accounts list dumped to: /Outputs/All_Accounts.txt" -ForegroundColor Yellow
                }
            }
            else{
                $all_accounts | Format-Table -Property DisplayName, UserPrincipalName, ObjectID,UserType -Wrap -RepeatHeader | more
            }
        }
    }
    catch {
        Write-Host "[x] Failed to search accounts in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetAllAADGroups {
    #Search all groups
    try {
        Write-Host "[*] Searching groups in tenant" -ForegroundColor Gray
        $all_groups = Get-AzureADGroup -All $true  
        
        #Check if output is too large
        if ($all_groups.Count -gt 20){
            Write-Host "[+] Found $($all_groups.Count) accounts in tenant" -ForegroundColor Yellow
            $user_input = Read-Host "`n[?] Display them all (y/n)"
            if ($user_input -eq "y"){
                $all_groups | Format-Table -Wrap | more
            }
            else{
                Write-Host "[*] Exporting groups list from tenant" -ForegroundColor Gray
                $all_groups | Out-File -FilePath .\Outputs\All_Groups.txt -Append
                Write-Host "[+] Group list dumped to: /Outputs/All_Groups.txt" -ForegroundColor Yellow
            }
        }
        else{
            $all_groups | Format-Table -Wrap | more
        }
    }
    catch {
        Write-Host "[x] Failed to search groups in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetAllMailboxes ($download = $false){
    #List all accounts
    try {
        Write-Host "[*] Searching mailboxes in tenant" -ForegroundColor Gray
        $all_mailboxes = Get-Mailbox 
        if ($download -eq $true){
            Write-Host "[*] Exporting mailbox list from tenant" -ForegroundColor Gray
            $all_mailboxes | Out-File -FilePath .\Outputs\All_Mailboxes.txt -Append
            Write-Host "[+] Mailbox list dumped to: /Outputs/All_Mailboxes.txt" -ForegroundColor Yellow
        }
        else{
            Write-Host "[+] Found $($all_mailboxes.Count) mailboxes in tenant" -ForegroundColor Yellow
            Read-Host "`n[?] Press enter to display all mailboxes"
            $all_mailboxes | Format-Table -Property DisplayName,PrimarySmtpAddress | more
        }
    }
    catch {
        Write-Host "[x] Failed to list mailboxes in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetAllServicePrincipal {
    #List all service principaals
    try {
        Write-Host "[*] Finding service principals in tenant" -ForegroundColor Gray
        $all_service_principal = Get-AzureADServicePrincipal 
        Write-Host "[+] Found $($all_service_principal.Count) service principals in tenant" -ForegroundColor Yellow
        Read-Host "`n[?] Press enter to display all service principals"
        
        $all_service_principal | Format-Table DisplayName, AppId, ObjectId -Wrap | more
    }
    catch {
        Write-Host "[x] Failed to find service principals in tenant" -ForegroundColor Red
    }
    Pause
}

function ListAuthorizationPolicy {
    #List all authorization policies
    try {
        Write-Host "[*] Finding authorization policies in tenant" -ForegroundColor Gray
        $all_auth_policy = Get-AzureADMSAuthorizationPolicy 
        Write-Host "[+] Found $($all_auth_policy.Count) authorization policies in tenant" -ForegroundColor Yellow
        Read-Host "`n[?] Press enter to display all service principals"

        $all_auth_policy | Format-Table | more
    }
    catch {
        Write-Host "[x] Failed to find authorization policies in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetNamedLocations {
    #List all named locations
    try {
        Write-Host "[*] Finding named locations in tenant" -ForegroundColor Gray
        $all_named_locations = Get-AzureADMSNamedLocationPolicy 
        Write-Host "[+] Found $($all_named_locations.Count) named locations in tenant" -ForegroundColor Yellow
        Read-Host "`n[?] Press enter to display all named locations"

        $all_named_locations | Format-Table DisplayName, IsTrusted, IpRanges, CountriesAndRegions -Wrap | more
    }
    catch {
        Write-Host "[x] Failed to find named locations in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetConditionalAccessPolicies {
    try {
        #Get conditional access policies
        Write-Host "[*] Finding CAP in tenant" -ForegroundColor Gray
        Get-AzureADMSConditionalAccessPolicy | Format-Table DisplayName, Id, State
        Write-Host "[*] Gathering detailed information on each policy below" -ForegroundColor Gray

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
        Write-Host "[x] Failed to find conditional access policies in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetRegisteredDevices {
    #List all user's registered devices
    try {
        $target_account = Read-Host "`n[?] Enter a user account to retrieve its registered devices"
        Write-Host ""
        Write-Host "[*] Finding registered devices for the account" -ForegroundColor Gray
        $user_reg_devices = Get-AzureADUserRegisteredDevice -ObjectId $target_account 

        Write-Host "[+] Found $($user_reg_devices.Count) registered devices for user" -ForegroundColor Yellow
        Read-Host "`n[?] Press enter to display all registered devices for user"
        
        $user_reg_devices | Format-Table -Wrap | more
        
    }
    catch {
        Write-Host "[x] Failed to find registered devices for the account" -ForegroundColor Red
    }
    Pause
}

function MAADGetAccessibleTenants {
    #List all accessible tenants
    try {
        Write-Host "[*] Listing all accessible tenant..." -ForegroundColor Gray
        Get-AzTenant | Format-Table
    }
    catch {
        Write-Host "[x]Failed to find accessible tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetAllSharepointSites ($teams_connected = $false){
    #List all accessible sites in tenants
    try {
        if ($teams_connected -eq $true){
            Write-Host "[*] Searching for teams connected SharePoint sites in tenant" -ForegroundColor Gray
            $all_sites = Get-SPOSite | ?{$_.IsTeamsConnected -eq $true}
        }
        else{
            Write-Host "[*] Searching for all SharePoint sites in tenant" -ForegroundColor Gray 
            $all_sites = Get-SPOSite 
            
        }
        $all_sites
        Write-Host "[+] Found $($all_sites.Count) sites in tenant" -ForegroundColor Yellow
        
        Read-Host "`n[?] Press enter to display all sites"
        $all_sites | Format-Table -Property Title,URL,SharingCapability | more
    }
    catch {
        Write-Host "[x] Failed to find SharePoint sites in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetAllTeams{
    #List all teams tenants
    try {
        Write-Host "[*]Searching for all teams sites in tenant" -ForegroundColor Gray
        $all_teams = Get-Team 
        Write-Host "[+] Found $($all_teams.Count) teams in tenant" -ForegroundColor Yellow
        
        Read-Host "`n[?] Press enter to display all teams"
        $all_teams  | Format-Table  DisplayName,GroupID,Description,Visibility -RepeatHeader| more
    }
    catch {
        Write-Host "[x] Failed to find teams in tenant" -ForegroundColor Red
    }
    Pause
}

function MAADGetAllDirectoryRoles {
    #Get all directory roles in Azure AD
    Write-Host ""
    Write-Host "[*] Finding directory roles in tenant" -ForegroundColor Gray
    $all_directory_roles = Get-AzureADDirectoryRole

    #Create custom object with all directory roles
    $seq = 1
    $directory_role_list = @()

    foreach ($directory_role in $all_directory_roles){
        $directory_role_list += [PSCustomObject]@{"seq" = $seq; "DirectoryRole" = $directory_role.DisplayName; "ObjectID" = $directory_role.ObjectID} 
        $seq += 1
    }

    Write-Host "[+] Found $($all_directory_roles.Count) directory roles in tenant" -ForegroundColor Yellow

    Read-Host "`n[?] Press enter to display all directory roles"
    #Display as table
    $directory_role_list | Format-Table @{Label="Directory Role";Expression={$_.DirectoryRole}}, @{Label="Object ID";Expression={$_.ObjectID}}
    Pause
 }

function MAADGetDirectoryRoleMembers {
    do {
        #Get all directory roles in Azure AD
        Write-Host ""
        Write-Host "[*] Finding directory roles in tenant" -ForegroundColor Gray
        $all_directory_roles = Get-AzureADDirectoryRole

        #Create custom object with all directory roles
        $seq = 1
        $directory_role_list = @()

        foreach ($directory_role in $all_directory_roles){
            $directory_role_list += [PSCustomObject]@{"seq" = $seq; "DirectoryRole" = $directory_role.DisplayName; "ObjectID" = $directory_role.ObjectID} 
            $seq += 1
        }

        Write-Host "[+] Found $($all_directory_roles.Count) directory roles in tenant" -ForegroundColor Yellow

        Read-Host "`n[?] Press enter to display all directory roles"
        #Display as table
        $directory_role_list | Format-Table @{Label="#";Expression={$_.seq}}, @{Label="Directory Roles";Expression={$_.DirectoryRole}}, @{Label="Object ID";Expression={$_.ObjectID}}

        $user_input = Read-Host "`n[?] Select a directory role from the list"
        
    } while ($user_input -notin $directory_role_list.seq)

    $target_directory_role = ($directory_role_list |Where-Object {$_.seq -eq $user_input}).DirectoryRole
    $target_directory_role_object_id = ($directory_role_list |Where-Object {$_.seq -eq $user_input}).ObjectID

    Write-Host ""
    $all_members = Get-AzureADDirectoryRoleMember -ObjectId $target_directory_role_object_id

    Write-Host "[+] Found $($all_members.Count) members in directory role $target_directory_role" -ForegroundColor Yellow

    Read-Host "`n[?] Press enter to display all members of directory role"

    #Create custom object with all directory role members
    $directory_role_members_list = @()

    foreach ($directory_role_member in $all_members){
        $directory_role_members_list += [PSCustomObject]@{"Member" = $directory_role_member.DisplayName; "MemberType" = $directory_role_member.UserType; "ObjectID" = $directory_role_member.ObjectID} 
    }
    #Display in table
    $directory_role_members_list | Format-Table @{Label="Directory Role Member";Expression={$_.Member}}, @{Label="Object ID";Expression={$_.ObjectID}}, @{Label="Type";Expression={$_.MemberType}}
    Pause

 }

 function MAADGetAccountDirectoryRoles {
    #Get all group roles in Azure AD
    Write-Host ""
    Write-Host "[*] Finding directory roles in tenant" -ForegroundColor Gray
    $all_directoryroles = Get-AzureADDirectoryRole
 
    #Get target account
    EnterAccount ("Enter an account to recon directory roles for")
    $target_account = $global:account_username
     
    $user_roles = @()
 
    Write-Host "[*] Enumerating through directory roles" -ForegroundColor Gray
 
    foreach ($role in $all_directoryroles){
        $role_object_id = $role.ObjectId
        if ($target_account -in (Get-AzureADDirectoryRoleMember -ObjectId $role_object_id).UserPrincipalName) {
            $user_roles += [PSCustomObject]@{"DirectoryRole" = $role.DisplayName}
        }
    }

    Write-Host "[+] User has: $($user_roles.Count)/$($all_directoryroles.Count) directory roles" -ForegroundColor Yellow

    if ($user_roles.Count -gt 0) {
        #Write-Host "[*] Following directory roles are assigned to user $target_account" -ForegroundColor Gray
        $user_roles | Format-Table @{Label="Directory Role";Expression={$_.DirectoryRole}}
    }
    Pause
}

function MAADGetAllRoleGroups {
    #Get all role groups in tenant
    Write-Host ""
    Write-Host "[*] Finding management role groups in tenant" -ForegroundColor Gray
    $all_roles_groups = Get-RoleGroup

    #Create custom object with all role groups
    $seq = 1
    $role_groups_list = @()

    foreach ($role_group in $all_roles_groups){
        $role_groups_list += [PSCustomObject]@{"RoleGroup" = $role_group.DisplayName}
        $seq += 1
    }
    Write-Host "[+] Found $($all_roles_groups.Count) role groups in tenant" -ForegroundColor Yellow

    Read-Host "`n[?] Press enter to display all role groups"
    #Display as table
    $role_groups_list | Format-Table @{Label="Role Group";Expression={$_.RoleGroup}}
    Pause
}

function MAADGetRoleGroupMembers {

    do {
        #Get all role groups in tenant
        Write-Host ""
        Write-Host "[*] Finding management role groups in tenant" -ForegroundColor Gray
        try {
            $all_roles_groups = Get-RoleGroup
        }
        catch {
            Write-Host "[x] Failed to recon management roles" -ForegroundColor Red
            return
        }

        #Create custom object with all role groups
        $seq = 1
        $role_groups_list = @()

        foreach ($role_group in $all_roles_groups){
            $role_groups_list += [PSCustomObject]@{"seq" = $seq; "RoleGroup" = $role_group.DisplayName}
            $seq += 1
        }
        Write-Host "[+] Found $($all_roles_groups.Count) role groups in tenant" -ForegroundColor Yellow

        Read-Host "`n[?] Press enter to display all role groups"
        #Display as table
        $role_groups_list | Format-Table @{Label="#";Expression={$_.seq}}, @{Label="Role Group";Expression={$_.RoleGroup}}

        $user_input = Read-Host "`n[?] Select a role group from the list"
    } while ($user_input -notin $role_groups_list.seq)
    
    $target_role_group = ($role_groups_list | Where-Object {$_.seq -eq $user_input}).RoleGroup

    Write-Host ""
    try {
        $all_members = Get-RoleGroupMember -Identity $target_role_group
    }
    catch {
        Write-Host "[x] Failed to recon management role members" -ForegroundColor Red
        return
    }

    Write-Host "[+] Found $($all_members.Count) members in role group $target_role_group" -ForegroundColor Yellow

    Read-Host "`n[?] Press enter to display all members of role group"

    #Create custom object with all role group members
    $role_group_members_list = @()

    foreach ($role_group_member in $all_members){
        $role_group_members_list += [PSCustomObject]@{"Member" = $role_group_member.Name; "Alias" = $role_group_member.Alias}
    }
    #Display in table
    $role_group_members_list | Format-Table @{Label="Role Group Member";Expression={$_.Member}}, Alias
    Pause
}

function MAADGetAllManagementRole {
    #Get all management roles in tenant
    Write-Host ""
    Write-Host "[*] Finding management roles in tenant" -ForegroundColor Gray
    $all_management_roles = Get-ManagementRole
    
    #Create custom object with all management roles
    $seq = 1
    $management_roles_list = @()

    foreach ($management_role in $all_management_roles){
        $management_roles_list += [PSCustomObject]@{"ManagementRole" = $management_role.Name}
        $seq += 1
    }
    Write-Host "[+] Found $($all_management_roles.Count) management roles in tenant" -ForegroundColor Yellow

    Read-Host "`n[?] Press enter to display all management roles"
    #Display as table
    $management_roles_list | Format-Table @{Label="Management Role";Expression={$_.ManagementRole}} | more
    Pause
}

function MAADGetAllEdiscoveryAdmins {
    Write-Host ""
    Write-Host "[*] Finding eDiscovery Admins in tenant" -ForegroundColor Gray
    try {
        $all_ediscovery_admins = Get-eDiscoveryCaseAdmin

        Write-Host "[+] Found $($all_ediscovery_admins.Count) eDiscovery Admins in tenant" -ForegroundColor Yellow

        if ($all_ediscovery_admins.Count -gt 0) {
            Read-Host "`n[?] Press enter to display all eDiscovery Admins"
        }

        $all_ediscovery_admins | Format-Table @{Label="eDiscovery Admin";Expression={$_.Name}}, @{Label="Email Address";Expression={$_.PrimarySmtpAddress}}, Title
    }
    catch {
        Write-Host "[x] Failed to recon eDiscovery Admins" -ForegroundColor Red
    }
    Pause
    
}