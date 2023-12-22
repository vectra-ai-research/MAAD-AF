#Reconnaissance modules
function MAADGetAllAADUsers ($download = $false){
    #Search all accounts
    Write-Host ""

    try {
        MAADWriteProcess "Searching accounts in tenant"
        $all_accounts = Get-AzureADUser -All $true 
        
        #Check if output is too large
        if ($download -eq $true){
            $output_time_stamp = Get-Date -Format "MMM dd yyyy HH:mm:ss"
            "$output_time_stamp `n--------------------" | Out-File -FilePath .\Outputs\All_Accounts.txt -Append
            $all_accounts | Out-File -FilePath .\Outputs\All_Accounts.txt -Append -Width 10000
            MAADWriteProcess "Output Saved -> MAAD-AF\Outputs\All_Accounts.txt"
        }
        else{
            Show-MAADOutput -large_limit 5 -output_list $all_accounts -file_path ".\Outputs\AAD_Accounts.txt"
        }
    }
    catch {
        MAADWriteError "Failed to search accounts in tenant"
    }
    MAADPause
}

function MAADGetAllAADGroups {
    #Search all groups
    Write-Host ""

    try {
        MAADWriteProcess "Searching groups in tenant"
        $all_groups = Get-AzureADGroup -All $true  
        # MAADWriteProcess "Found $($all_groups.Count) groups"

        Show-MAADOutput -large_limit 5 -output_list $all_groups -file_path ".\Outputs\AAD_Groups.txt"
    }
    catch {
        MAADWriteError "Failed to search groups in tenant"
    }
    MAADPause
}

function MAADGetAllMailboxes ($download = $false){
    #List all mailboxes
    Write-Host ""

    try {
        MAADWriteProcess "Searching mailboxes in tenant"
        $all_mailboxes = Get-Mailbox | Select-Object DisplayName, PrimarySmtpAddress, AuditEnabled

        if ($download -eq $true){
            $output_time_stamp = Get-Date -Format "MMM dd yyyy HH:mm:ss"
            "$output_time_stamp `n--------------------" | Out-File -FilePath .\Outputs\All_Mailboxes.txt -Append
            $all_mailboxes | Out-File -FilePath .\Outputs\All_Mailboxes.txt -Append -Width 10000
            MAADWriteProcess "Output Saved -> MAAD-AF\Outputs\All_Mailboxes.txt"
        }
        else{
            Show-MAADOutput -large_limit 5 -output_list $all_mailboxes -file_path ".\Outputs\Exchange_Mailboxes.txt"
        }
    }
    catch {
        MAADWriteError "Failed to search mailboxes in tenant"
    }
    MAADPause
}

function MAADGetAllServicePrincipal {
    #List all service principals
    Write-Host ""

    try {
        MAADWriteProcess "Searching service principals in tenant"
        $all_service_principal = Get-AzureADServicePrincipal 

        Show-MAADOutput -large_limit 10 -output_list $all_service_principal -file_path ".\Outputs\AAD_Service_Princiapls.txt"
    }
    catch {
        MAADWriteError "Failed to find service principals in tenant"
    }
    MAADPause
}


function ListAuthorizationPolicy {
    #List all authorization policies
    Write-Host ""

    try {
        MAADWriteProcess "Searching authorization policies in tenant"
        $all_auth_policy = Get-AzureADMSAuthorizationPolicy 

        Show-MAADOutput -large_limit 10 -output_list $all_auth_policy -file_path ".\Outputs\AAD_Authorization_Policies.txt"
    }
    catch {
        MAADWriteError "Failed to find authorization policies in tenant"
    }
    MAADPause
}

function MAADGetNamedLocations {
    #List all named locations
    Write-Host ""

    try {
        MAADWriteProcess "Searching named locations in tenant"
        $all_named_locations = Get-AzureADMSNamedLocationPolicy 

        Show-MAADOutput -large_limit 10 -output_list $all_named_locations -file_path ".\Outputs\AAD_Named_Locations.txt"

        # MAADWriteProcess "Found $($all_named_locations.Count) named locations in tenant"
        # Read-Host "`n[?] Press enter to display all named locations"
        # Write-Host ""
        # MAADWriteProcess "Displaying Named Locations"

        # $all_named_locations | Format-Table DisplayName, IsTrusted, IpRanges, CountriesAndRegions -Wrap | more
    }
    catch {
        MAADWriteError "Failed to find Named Locations in tenant"
    }
    MAADPause
}

function MAADGetConditionalAccessPolicies {
    #Get conditional access policies
    Write-Host ""

    try {
        MAADWriteProcess "Searching Conditional Access Policies in tenant"

        $all_conditional_policy = Get-AzureADMSConditionalAccessPolicy

        MAADWriteProcess "Found $($all_conditional_policy.Count) conditional access policies"

        #Save Output to file
        $file_path = ".\Outputs\All_CAP.txt"
        $output_time_stamp = Get-Date -Format "MMM dd yyyy HH:mm:ss"
        "`n$output_time_stamp `n--------------------" | Out-File -FilePath $file_path -Append

        foreach ($policy in $all_conditional_policy){
            "###########################################" | Out-File -FilePath $file_path -Append
            "Policy Name: $($policy.DisplayName)" | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            "Policy State: $($policy.State)" | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            "Policy ID: $($policy.Id)" | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            "Policy Conditions:" | Out-File -FilePath $file_path -Append
            $($policy.Conditions.Applications) | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            $($policy.Conditions.Users) | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            $($policy.Conditions.Platforms) | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            $($policy.Conditions.Locations) | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            $($policy.Conditions.SignInRiskLevels) | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
            $($policy.Conditions.ClientAppTypes) | Format-Table -Wrap -AutoSize | Out-File -FilePath $file_path -Append
        }

        MAADWriteProcess "Output Saved -> \MAAD-AF\Outputs\All_CAP.txt"

        if ($all_conditional_policy.Count -gt 5){
            $user_input = Read-Host "`n[?] Display full results (y/n)"
            Write-Host ""
            if ($user_input -eq "y"){
                MAADWriteProcess "Large Output -> Checkout results in MAAD-AF Output view"

                $script = {
                    $name = 'MAAD-AF Output View'
                    $host.ui.RawUI.WindowTitle = $name
                }
                Start-Process powershell -ArgumentList "-NoExit $script `"Get-Content -Path $file_path; Read-Host `"Press [enter] to exit`" ;exit`""
            }
        }
        else {
            MAADWriteProcess "Checkout results in MAAD-AF Output view"
            Start-Process powershell -ArgumentList "-NoExit $script `"Get-Content -Path $file_path; Read-Host `"Press [enter] to exit`" ;exit`""
        }
    }
    catch {
        MAADWriteError "Failed to find Conditional Access Policies in tenant"
    }
    MAADPause
}

function MAADGetRegisteredDevices {
    #List all user's registered devices
    Write-Host ""

    try {
        EnterAccount "`n[?] Enter account to retrieve registered devices"
        $target_account = $global:account_username
        MAADWriteProcess "Searching registered devices"
        $user_reg_devices = Get-AzureADUserRegisteredDevice -ObjectId $target_account 

        Show-MAADOutput -large_limit 10 -output_list $user_reg_devices -file_path ".\Outputs\AAD_User_Registed_Devices.txt"
    }
    catch {
        MAADWriteError "Failed to find registered devices for the account"
    }
    MAADPause
}

function MAADGetAccessibleTenants {
    #List all accessible tenants
    Write-Host ""

    try {
        MAADWriteProcess "Searching accessible tenants for account"
        $all_tenants = Get-AzTenant

        Show-MAADOutput -large_limit 10 -output_list $all_tenants -file_path ".\Outputs\AAD_Accessible_Tenants.txt"
    }
    catch {
        MAADWriteError "Failed to find accessible tenant"
    }
    MAADPause
}

function MAADGetAllSharepointSites ($teams_connected = $false){
    #List all accessible sites in tenants
    Write-Host ""

    try {
        if ($teams_connected -eq $true){
            MAADWriteProcess "Searching Teams connected SharePoint sites in tenant"
            $all_sites = Get-SPOSite | ?{$_.IsTeamsConnected -eq $true}
        }
        else{
            MAADWriteProcess "Searching all SharePoint sites in tenant" 
            $all_sites = Get-SPOSite 
            
        }

        Show-MAADOutput -large_limit 10 -output_list $all_sites -file_path ".\Outputs\M365_SharePoint_Sites.txt"
    }
    catch {
        MAADWriteError "Failed to find SharePoint sites in tenant"
    }
    MAADPause
}

function MAADGetAllTeams{
    #List all teams tenants
    Write-Host ""

    try {
        MAADWriteProcess "Searching all Teams in tenant"
        $all_teams = Get-Team 

        Show-MAADOutput -large_limit 10 -output_list $all_teams -file_path ".\Outputs\M365_Teams.txt"
    }
    catch {
        MAADWriteError "Failed to find teams in tenant"
    }
    MAADPause
}

function MAADGetAllDirectoryRoles {
    #Get all directory roles in Azure AD
    Write-Host ""

    try {
        MAADWriteProcess "Searching directory roles in tenant"
        $all_directory_roles = Get-AzureADDirectoryRole | Select-Object DisplayName, ObjectID

        #Create custom object with all directory roles
        $seq = 1
        $directory_role_list = @()

        foreach ($directory_role in $all_directory_roles){
            $directory_role_list += [PSCustomObject]@{"Seq" = $seq; "DirectoryRole" = $directory_role.DisplayName; "ObjectID" = $directory_role.ObjectID} 
            $seq += 1
        }

        Show-MAADOutput -large_limit 10 -output_list $directory_role_list -file_path ".\Outputs\AAD_Directory_Roles.txt"
    }
    catch {
        MAADWriteError "Failed to find directory roles in tenant"
    }
    MAADPause
 }

function MAADGetDirectoryRoleMembers {
    try {
        do {
            #Get all directory roles in Azure AD
            Write-Host ""
            MAADWriteProcess "Finding directory roles in tenant"
            $all_directory_roles = Get-AzureADDirectoryRole

            #Create custom object with all directory roles
            $seq = 1
            $directory_role_list = @()

            foreach ($directory_role in $all_directory_roles){
                $directory_role_list += [PSCustomObject]@{"seq" = $seq; "DirectoryRole" = $directory_role.DisplayName; "ObjectID" = $directory_role.ObjectID} 
                $seq += 1
            }
            
            #Display as table
            $directory_role_list | Format-Table @{Label="#";Expression={$_.seq}}, @{Label="Directory Roles";Expression={$_.DirectoryRole}}, @{Label="Object ID";Expression={$_.ObjectID}}

            $user_input = Read-Host "`n[?] Select a directory role from the list"
            Write-Host ""
            
        } while ($user_input -notin $directory_role_list.seq)

        $target_directory_role = ($directory_role_list |Where-Object {$_.seq -eq $user_input}).DirectoryRole
        $target_directory_role_object_id = ($directory_role_list |Where-Object {$_.seq -eq $user_input}).ObjectID

        $all_members = Get-AzureADDirectoryRoleMember -ObjectId $target_directory_role_object_id

        #Create custom object with all directory role members
        $directory_role_members_list = @()

        foreach ($directory_role_member in $all_members){
            $directory_role_members_list += [PSCustomObject]@{"DirectoryRole" = $target_directory_role; "Member" = $directory_role_member.DisplayName; "MemberType" = $directory_role_member.UserType; "ObjectID" = $directory_role_member.ObjectID} 
        }

        Show-MAADOutput -large_limit 10 -output_list $directory_role_members_list -file_path ".\Outputs\AAD_Directory_Role_Members.txt"
    }
    catch{
        MAADWriteError "Failed to find directory role members"
    }
    MAADPause

 }

 function MAADGetAccountDirectoryRoles {
    #Get all group roles in Azure AD
    Write-Host ""

    try {
        MAADWriteProcess "Finding directory roles in tenant"
        $all_directoryroles = Get-AzureADDirectoryRole
    
        #Get target account
        EnterAccount ("`n[?] Enter account to recon directory roles for")
        $target_account = $global:account_username
        
        $user_roles_list = @()
    
        MAADWriteProcess "Enumerating through directory roles"
    
        foreach ($role in $all_directoryroles){
            $role_object_id = $role.ObjectId
            if ($target_account -in (Get-AzureADDirectoryRoleMember -ObjectId $role_object_id).UserPrincipalName) {
                $user_roles_list += [PSCustomObject]@{"User" = $target_account ; "DirectoryRole" = $role.DisplayName}
            }
        }

        Show-MAADOutput -large_limit 10 -output_list $user_roles_list -file_path ".\Outputs\AAD_User_Directory_Roles.txt"
    }
    catch {
        MAADWriteError "Failed to find directory roles"
    }

    MAADPause
}

function MAADGetAllRoleGroups {
    #Get all role groups in tenant
    Write-Host ""

    try {
        MAADWriteProcess "Searching management role groups in tenant"
        $all_roles_groups = Get-RoleGroup

        #Create custom object with all role groups
        $seq = 1
        $role_groups_list = @()

        foreach ($role_group in $all_roles_groups){
            $role_groups_list += [PSCustomObject]@{"RoleGroup" = $role_group.DisplayName}
            $seq += 1
        }

        Show-MAADOutput -large_limit 10 -output_list $role_groups_list -file_path ".\Outputs\Roles_Groups.txt"
    }
    catch {
        MAADWriteError "Failed to find management role groups"
    }
    MAADPause
}

function MAADGetRoleGroupMembers {
    try {
        do {
            #Get all role groups in tenant
            Write-Host ""
            MAADWriteProcess "Searching management role groups in tenant"
            try {
                $all_roles_groups = Get-RoleGroup
            }
            catch {
                MAADWriteError "Failed to recon management roles"
                return
            }

            #Create custom object with all role groups
            $seq = 1
            $role_groups_list = @()

            foreach ($role_group in $all_roles_groups){
                $role_groups_list += [PSCustomObject]@{"seq" = $seq; "RoleGroup" = $role_group.DisplayName}
                $seq += 1
            }
            MAADWriteProcess "Found $($all_roles_groups.Count) role groups"

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
            MAADWriteError "Failed to recon management role members"
            return
        }

        #Create custom object with all role group members
        $role_group_members_list = @()

        foreach ($role_group_member in $all_members){
            $role_group_members_list += [PSCustomObject]@{"RoleGroup" = $target_role_group; "Member" = $role_group_member.Name; "Alias" = $role_group_member.Alias}
        }
        #Display in table
        Show-MAADOutput -large_limit 10 -output_list $role_group_members_list -file_path ".\Outputs\Role_Group_Members.txt"
    }
    catch {
        MAADWriteError "Failed to find role group members"
    }

    MAADPause
}

function MAADGetAllManagementRole {
    #Get all management roles in tenant
    Write-Host ""

    try {
        MAADWriteProcess "Finding management roles in tenant"
        $all_management_roles = Get-ManagementRole
        
        #Create custom object with all management roles
        $seq = 1
        $management_roles_list = @()

        foreach ($management_role in $all_management_roles){
            $management_roles_list += [PSCustomObject]@{"Seq" = $seq; "ManagementRole" = $management_role.Name}
            $seq += 1
        }

        Show-MAADOutput -large_limit 10 -output_list $management_roles_list -file_path ".\Outputs\Management_Roles.txt"
    }
    catch {
        MAADWriteError "Failed to recon management roles"
    }
    MAADPause
}

function MAADGetAllEdiscoveryAdmins {
    Write-Host ""

    MAADWriteProcess "Finding eDiscovery Admins in tenant"
    try {
        $all_ediscovery_admins = Get-eDiscoveryCaseAdmin

        Show-MAADOutput -large_limit 10 -output_list $all_ediscovery_admins -file_path ".\Outputs\EDiscovery_Admins.txt"
    }
    catch {
        MAADWriteError "Failed to recon eDiscovery Admins"
    }
    MAADPause   
}