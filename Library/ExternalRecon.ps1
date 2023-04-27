function ExternalRecon {
    Write-Host "`nExternal Recon allows you to gather intelligence on your target user/organization to leverage in further attacks" @bg_black @fg_yellow
    
    $recon_user_name = Read-Host -Prompt "`nEnter a username from an organization you want to target & recon (the tool will extract the domain from it)"

    if ($recon_user_name.Contains("@")) {
        $recon_domain = $recon_user_name.Split("@")[1]
    }

    Write-Host "`nThe tool will now perform several recon operations and gather open source intelligence on the user and organization's Azure environment. `n" @fg_yellow
    $null = Read-Host -Prompt "`nPress 'Enter' to continue" 

    #Check if a user account exists in the organization
    Write-Host "`nChecking if the user account exists in the Azure environment ...`n" @fg_yellow 
    if (Invoke-AADIntUserEnumerationAsOutsider -UserName $recon_user_name){
        Write-Host "`nResult: Account found!!! User account is a valid account in the organization!`n"
    }
    else {
        Write-Host "Result: Could not verify if the account exists in organization!`n"
    }
    #Check if a list of users exist in an organization
    #Get-Content .\users.txt | Invoke-AADIntUserEnumerationAsOutsider -Method Normal
    Pause

    #Get users login information
    Write-Host "`nGathering login information of the user ...`n" @fg_yellow 
    Get-AADIntLoginInformation -UserName $recon_user_name | Format-Table
    Pause

    #List other domains of the organization
    Write-Host "`nFinding all other domains of the organization ...`n" @fg_yellow 
    Get-AADIntTenantDomains -Domain $recon_domain | Format-Table
    Write-Host "`n"
    Pause

    #Gather all information on a domain
    Write-Host "`nGathering all information on the organization domain ...`n" @fg_yellow 
    Invoke-AADIntReconAsOutsider -DomainName $recon_domain | Format-Table
    Pause

    #Get tenant ID
    #Write-Host "`nFinding tenant ID of the domain ...`n" @fg_yellow 
    #Get-AADIntTenantID -Domain $recon_domain
    #Pause

    #Get DNS information
    Write-Host "`nGathering all DNS information on the organization domain ...`n" @fg_yellow 
    Resolve-DnsName -Name $recon_domain -Type MX | Format-Table
    Resolve-DnsName -Name $recon_domain -Type TXT | Format-Table
    Pause
}