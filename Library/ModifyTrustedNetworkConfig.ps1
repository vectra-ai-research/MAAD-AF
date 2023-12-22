function ModifyTrustedNetworkConfig {
    mitre_details("TrustedNetworkConfig")

    #Get public IP
    $trusted_policy_name = Read-Host -Prompt "`n[?] Enter name for new Trusted Network Policy"
    Write-Host ""
    MAADWriteInfo "Leave blank and press [enter] to automatically use your public IP"

    $ip_addr = Read-Host -Prompt "`n[?] Enter IP to add as trusted named location"
    Write-Host ""

    if ($ip_addr -eq "") {
        MAADWriteProcess "Resolving your public IP"
        MAADWriteProcess "Querying DNS"
        $ip_addr = $(Resolve-DnsName -Name myip.opendns.com -Server 208.67.222.220).IPAddress
        MAADWriteProcess "Your public IP -> $ip_addr"
        MAADPause

        if ($ip_addr -eq "") {
            MAADWriteError "Failed to resolve IP automatically"
            $ip_addr = Read-Host -Prompt "`n[?] Manually enter IP address to add as trusted named location"
            Write-Host ""
        }
    }
    
    #Create trusted network policy
    try {
        MAADWriteProcess "Deploying policy -> $trusted_policy_name"
        $trusted_nw = New-AzureADMSNamedLocationPolicy -OdataType "#microsoft.graph.ipNamedLocation" -DisplayName $trusted_policy_name -IsTrusted $true -IpRanges "$ip_addr/32" -ErrorAction Stop
        MAADWriteProcess "Trusted network policy created"
        MAADWriteProcess "Retrieving details of deployed policy"
        MAADWriteProcess "Policy Name -> $($trusted_nw.DisplayName)"
        MAADWriteProcess "Policy ID -> $($trusted_nw.Id)"
        MAADWriteProcess "Trusted IP Range -> $($trusted_nw.IpRanges.CidrAddress)"
        MAADWriteSuccess "Deployed Trusted Network Policy"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to deploy trusted network policy"
    }
    
    #Undo changes
    if ($allow_undo -eq $true) {
        $user_confirm = Read-Host -Prompt "`n[?] Undo: Delete new trusted network policy (y/n)"
        Write-Host ""

        if ($user_confirm -notin "No","no","N","n") {
            try {
                MAADWriteProcess "Removing Trusted Network Policy"
                Remove-AzureADMSNamedLocationPolicy -PolicyId $trusted_nw.Id
                MAADWriteSuccess "Deleted New Trusted Location Policy"
            }
            catch {
                MAADWriteError "Failed to delete new trusted network policy"
            }
        }
    }
    MAADPause
}