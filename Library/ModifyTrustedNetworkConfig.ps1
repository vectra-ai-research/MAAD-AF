function ModifyTrustedNetworkConfig {
    mitre_details("TrustedNetworkConfig")

    #Get public IP
    $trusted_policy_name = Read-Host -Prompt "Enter a name for the new trusted network policy"

    $ip_addr = Read-Host -Prompt "`nEnter IP to add as trusted named location (or leave blank and hit 'enter' to automatically resolve and use your public IP)"

    if ($ip_addr -eq "") {
        Write-Host "`nResolving your public IP..." -ForegroundColor Gray
        Write-Host "    Querying DNS..." -ForegroundColor Gray
        $ip_addr = $(Resolve-DnsName -Name myip.opendns.com -Server 208.67.222.220).IPAddress
        Write-Host "`nYour public IP: $ip_addr`n"
        Pause

        if ($ip_addr -eq "") {
            Write-Host "`n[Error] Failed to resolve IP automatically." -ForegroundColor Red
            $ip_addr = Read-Host -Prompt "`nManually enter IP address to add as trusted named location"
        }
    }
    
    #Create trusted network policy
    try {
        Write-Host "`nDeploying policy $trusted_policy_name to add your IP as trusted named location..." -ForegroundColor Gray
        $trusted_nw = New-AzureADMSNamedLocationPolicy -OdataType "#microsoft.graph.ipNamedLocation" -DisplayName $trusted_policy_name -IsTrusted $true -IpRanges "$ip_addr/32" -ErrorAction Stop
        Write-Host "`nDisplaying details of deployed policy ..." -ForegroundColor Gray
        $trusted_nw | Out-Host
        Write-Host "[Success] CreDeployedated trusted location policy: $trusted_policy_name with IP: $ip_addr" -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "[Error] Failed to create trusted location policy!"
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt "`nWould you like to undo changes by deleting the new trusted location policy? (yes/no)"

        if ($user_confirm -notin "No","no","N","n") {
            try {
                Write-Host "`nRemoving trusted location policy: $trusted_policy_name ...`n" -ForegroundColor Gray
                Remove-AzureADMSNamedLocationPolicy -PolicyId $trusted_nw.Id
                Write-Host "[Undo success] Removed the trusted location policy" -ForegroundColor Yellow
            }
            catch {
                Write-Host "[Error] Failed to remove the trusted location policy!!!" -ForegroundColor Red
            }
            
        }
    }
    Pause
}