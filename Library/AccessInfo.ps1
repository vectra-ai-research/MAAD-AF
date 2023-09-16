#AccessInfo
function AccessInfo{

    Write-Host "`nGathering information on current access & privilege..." -ForegroundColor Gray

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

    Write-Host "`n########################################################################`n" -ForegroundColor Gray

    Write-Host "Connected Services/Modules:" -ForegroundColor Gray
    if ($access_status_azure_ad) {Write-Host "- Azure AD" -ForegroundColor Gray}
    if ($access_status_az) {Write-Host "- Az" -ForegroundColor Gray}
    if ($access_status_exchange_online) {Write-Host "- Exchange Online" -ForegroundColor Gray}
    if ($access_status_teams) {Write-Host "- Teams" -ForegroundColor Gray}
    if ($access_status_msol) {Write-Host "- Msol" -ForegroundColor Gray}
    if ($access_status_sp_site) {Write-Host "- Sharepoint Site" -ForegroundColor Gray}
    if ($access_status_spo_admin) {Write-Host "- Sharepoint Admin" -ForegroundColor Gray}
    if ($access_status_ediscovery) {Write-Host " -Compliance Center" -ForegroundColor Gray}
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
            $account_owned_objects_name += $membership.DisplayName
        }

        $account_all_roles = $account_role_name -join ', '
        $account_all_groups = $account_group_name -join ', '
        $account_all_owned = $account_owned_objects_name -join ', '
        
        Write-Host "Tenant: $tenant_id`n" -ForegroundColor Gray
        Write-Host "Logged in as: $logged_in_user`n" -ForegroundColor Gray
        Write-Host "Roles assigned: $account_all_roles`n" -ForegroundColor Gray
        Write-Host "Groups member of: $account_all_groups`n" -ForegroundColor Gray
        Write-Host "Owner of: $account_all_owned`n" -ForegroundColor Gray
    }
    catch {
        Write-Host "Tenant: N/A`n" -ForegroundColor Gray
        Write-Host "Logged in as: N/A`n" -ForegroundColor Gray
        Write-Host "Roles assigned: N/A`n" -ForegroundColor Gray
        Write-Host "Groups member of: N/A`n" -ForegroundColor Gray
        Write-Host "Owner of: N/A`n" -ForegroundColor Gray
    }

    Write-Host "########################################################################`n" -ForegroundColor Gray
}


