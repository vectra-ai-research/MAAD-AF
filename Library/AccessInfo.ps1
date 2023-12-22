#AccessInfo
function AccessInfo{
    Write-Host ""
    MAADWriteProcess "Fetching current access info"

    try {
        $azure_ad_session_info = Get-AzureADCurrentSessionInfo -ErrorAction Stop 
        $access_status_azure_ad = $true
    }
    catch {
        $access_status_azure_ad = $false
    }

    try {
        $az_context = Get-AzContext -ErrorAction Stop
        if ($null -eq $az_context) {
            $access_status_az = $false
        }
        else {
            $access_status_az = $true
        }
        #$az_context.Account.Id
    }
    catch {
        $access_status_az = $false
    }

    try {
        $teams_session_info = Get-AssociatedTeam -ErrorAction Stop
        $access_status_teams = $true
        #$connected_teams = $teams_session_info.DisplayName
    }
    catch {
        $access_status_teams = $false
    }

    try {
        $access_status_exchange_online = $false
        $exchangle_online_session_info = Get-ConnectionInformation -ErrorAction Stop
        if ($null -eq $exchangle_online_session_info) {
            $access_status_exchange_online = $false
        }
        else {
            foreach ($connection in $exchangle_online_session_info){
                if ($connection.ConnectionUri -eq "https://outlook.office365.com") {
                    $access_status_exchange_online = $true
                }
            }
        }
        #$exchangle_online_session_info..UserPrincipalname
    }
    catch {
        $access_status_exchange_online = $false
    }

    try {
        $msol_session_info = Get-MsolDomain -ErrorAction Stop
        $access_status_msol = $true
        #Get-MsolUserRole
    }
    catch {
        $access_status_msol = $false
    }

    try {
        $sp_site_session_info = Get-PnPConnection -ErrorAction Stop
        $access_status_sp_site = $true
    }
    catch {
        $access_status_sp_site = $false
    }

    try {
        $spo_admin_session_info = Get-SPOTenant -ErrorAction Stop
        $access_status_spo_admin = $true
    }
    catch {
        $access_status_spo_admin = $false
    }

    try {
        $access_status_ediscovery = $false
        $ediscovery_session_info = Get-ConnectionInformation -ErrorAction Stop
        if ($null -eq $ediscovery_session_info) {
            $access_status_ediscovery = $false
        }
        else {
            foreach ($connection in $ediscovery_session_info){
                if ($connection.ConnectionUri -eq "https://nam10b.ps.compliance.protection.outlook.com") {
                    $access_status_ediscovery = $true
                }
            }
        }
    }
    catch {
        $access_status_ediscovery = $false
    }

    $connected_modules = @()
    if ($access_status_azure_ad) {$connected_modules += "Azure AD"}
    if ($access_status_az) {$connected_modules += "Az"}
    if ($access_status_exchange_online) {$connected_modules += "Exchange Online"}
    if ($access_status_teams) {$connected_modules += "Teams"}
    if ($access_status_msol) {$connected_modules += "Msol"}
    if ($access_status_sp_site) {$connected_modules += "Sharepoint Site"}
    if ($access_status_spo_admin) {$connected_modules += "Sharepoint Admin"}
    if ($access_status_ediscovery) {$connected_modules += "Compliance Center"}
    Write-Host ""

    try {
        #Session Info
        $tenant_id = $azure_ad_session_info.TenantId.Guid

        $logged_in_user = $azure_ad_session_info.Account.Id

        $logged_in_user_id = (Get-AzureADUser -Filter "userPrincipalName eq '$logged_in_user'").ObjectId

        #Get all Memberships
        $account_membership = Get-AzureADUserMembership -ObjectId $logged_in_user_id
        #Get all owned objects
        $account_owned_objects = Get-AzureADUserOwnedObject -ObjectId $logged_in_user_id

        $account_role_name = @()
        $account_group_name = @()
        $account_owned_objects_name = @()

        foreach ($membership in $account_membership){
            if ($membership.ObjectType -eq "Role"){
                $account_role_name += $membership.DisplayName
            }
            if ($membership.ObjectType -eq "Group"){
                $account_group_name += $membership.DisplayName
            }
        }

        foreach ($objects in $account_owned_objects){
            $account_owned_objects_name += $objects.DisplayName
        }


        #Display access info
        MAADWriteInfo "Tenant"
        MAADWriteProcess "$tenant_id"
        Write-Host ""
        Start-Sleep -Seconds 1

        MAADWriteInfo "User"
        MAADWriteProcess "$logged_in_user"
        Write-Host ""
        Start-Sleep -Seconds 1

        MAADWriteInfo "Connected Services/ PS Modules"
        foreach ($connection in $connected_modules){
            MAADWriteProcess $connection
        }
        Write-Host ""
        Start-Sleep -Seconds 1

        MAADWriteInfo "Roles Assigned"
        foreach ($role in $account_role_name){
            MAADWriteProcess $role
        }
        Write-Host ""
        Start-Sleep -Seconds 1

        MAADWriteInfo "Group Membership"
        foreach ($group in $account_group_name){
            MAADWriteProcess $group
        }
        Write-Host ""
        Start-Sleep -Seconds 1

        MAADWriteInfo "Owner of"
        foreach ($object in $account_owned_objects_name){
            MAADWriteProcess $object
        }
    }
    catch {
        #Display access info
        MAADWriteInfo "Tenant"
        MAADWriteError "No Access"
        Write-Host ""

        MAADWriteInfo "User"
        MAADWriteError "No Access"
        Write-Host ""

        MAADWriteInfo "Connected Services/ PS Modules"
        MAADWriteError "No Access"
        Write-Host ""

        MAADWriteInfo "Roles"
        MAADWriteError "No Access"
        Write-Host ""

        MAADWriteInfo "Group Membership"
        MAADWriteError "No Access"
        Write-Host ""

        MAADWriteInfo "Owner of"
        MAADWriteError "No Access"
    }

    MAADPause
}


