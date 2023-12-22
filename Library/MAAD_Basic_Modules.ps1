###Basic functions
function RequiredModules {
    ###This function checks for required modules by MAAD and Installs them if unavailable. Some modules have specific version requirements specified in the dictionary values
    $RequiredModules=@{"Az.Accounts" = "2.13.1";"Az.Resources" = "6.11.2"; "AzureAd" = "2.0.2.182";"MSOnline" = "1.1.183.80";"ExchangeOnlineManagement" = "3.2.0";"MicrosoftTeams" = "5.7.0";"AADInternals" = "0.9.2";"Microsoft.Online.SharePoint.PowerShell" = "16.0.23710.12000";"PnP.PowerShell" = "1.12.0";"Microsoft.Graph.Identity.SignIns" = "2.6.1";"Microsoft.Graph.Applications" = "2.6.1";"Microsoft.Graph.Users" = "2.6.1";"Microsoft.Graph.Groups" = "2.6.1"}
    $missing_modules = @{}
    $installed_modules = @{}

    #Check for available modules
    MAADWriteProcess "Checking for dependencies"
    $installed_modules_count = 0
    foreach ($module in $RequiredModules.Keys) {
        try {
            if ($RequiredModules[$module] -ne "") {
                Get-InstalledModule -Name $module -RequiredVersion $RequiredModules[$module] -ErrorAction Stop
                $installed_modules_count+=1
                $installed_modules[$module] = $RequiredModules[$module]
            }
            else {
                Get-InstalledModule -Name $module -ErrorAction Stop
                $installed_modules_count+=1
                $installed_modules[$module] = $RequiredModules[$module]
            }
        }
        catch {
            #Add modules to missing modules dict
            $missing_modules[$module] = $RequiredModules[$module]
        }
    }

    #Display information and check user choice
    if ( $installed_modules_count -eq $RequiredModules.Count) {
        MAADWriteProcess "All required dependencies available"
        $allow = $null
    }
    elseif ($installed_modules_count -lt $RequiredModules.Count) {
        MAADWriteProcess "Modules currently installed -> $installed_modules_count / $($RequiredModules.Count)"
        MAADWriteProcess "MAAD-AF requires the following missing powershell modules"
        $missing_modules | Format-Table @{Label="PowerShell Module";Expression={$_.Name}}, @{Label="Required Version";Expression={$_.Value}}
        $allow = Read-Host -Prompt "`n[?] Install missing dependecies (y/n)"
    
        if ($null -eq $allow) {
            #Do nothing
        }
        elseif ($allow -notin "No","no","N","n") {
            MAADWriteProcess "Installing missing modules"

            Set-ExecutionPolicy Unrestricted -Force
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

            #Install missing modules
            foreach ($module in $missing_modules.Keys){
                MAADWriteProcess "Module missing -> $module"
                MAADWriteProcess "Installing -> $module"
                try {
                    if ($missing_modules[$module] -eq "") {
                        Install-Module -Name $module -Confirm:$False -WarningAction SilentlyContinue -ErrorAction Stop
                        #Add module to installed modules dict
                        $installed_modules[$module] = $RequiredModules[$module]
                        MAADWriteSuccess "Installed module -> $module"
                    }
                    else {
                        Install-Module -Name $module -RequiredVersion $missing_modules[$module] -Confirm:$False -WarningAction SilentlyContinue -ErrorAction Stop
                        $installed_modules[$module] = $RequiredModules[$module]
                        MAADWriteSuccess "Installed module -> $module"
                    }
                }
                catch {
                    MAADWriteError "Failed to install -> $module"
                    MAADWriteProcess "Skippig module -> $module"
                }   
            }
        }
        else {
            MAADWriteInfo "Some MAAD-AF techniques may fail if required modules are missing"
        } 
    }

    MAADWriteProcess "Modules installed -> $($installed_modules.Count) / $($RequiredModules.Count)"

    #Import all installed Modules
    MAADWriteProcess "Importing installed modules to current run space"
    foreach ($module in $installed_modules.Keys){
        #Remove any member of module from current run space
        try {
            Remove-Module -Name $module -ErrorAction Stop
        }
        catch {
            #Do nothing
        }
        
        try {
            if ($installed_modules[$module] -eq "") {
                Import-Module -Name $module -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
            }
            else {
                Import-Module -Name $module -RequiredVersion $installed_modules[$module] -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
            }
        }
        catch {
            MAADWriteError "Failed to import module"
            MAADWriteProcess "Skippig module import -> $module"
        }
    }       

    MAADWriteProcess "Dependency check completed"
    #Prevents overwrite from any imported modules 
    $host.UI.RawUI.WindowTitle = "MAAD Attack Framework"
    Write-MAADLog "info" "Modules check completed"
} 

function ClearActiveSessions {
    try {
        Get-PSSession | Remove-PSSession
    }
    catch {
        #Do nothing
    }
}

function DisplayCentre ($display_text,$text_colour) { 
    try {
        Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($display_text.Length / 2)))), $display_text) -ForegroundColor $text_colour
    }
    catch {
        Write-Host $display_text -ForegroundColor $text_colour
    } 
}

function OptionDisplay ($menu_message, $option_list_dictionary){
    ###This function diplays a list of options from a dictionary.
    Write-Host "`n$menu_message"
    $option_list_array = $option_list_dictionary.GetEnumerator() |sort Name

    foreach ($item in $option_list_array){
        Write-Host $item.Name ":" $item.Value 
    } 
}

function CreateOutputsDir {
    if ((Test-Path -Path ".\Outputs") -eq $false){
        New-Item -ItemType Directory -Force -Path .\Outputs | Out-Null
    }
}

function CreateLocalDir {
    #check if the directory exists, if not, create it
    if (! (Test-Path -Path ".\Local")){
        New-Item -ItemType Directory -Force -Path .\Local | Out-Null
    }

    #Create Credentials store if not present
    if (! (Test-Path -Path $global:maad_credential_store)){
        Out-File $global:maad_credential_store
    }

    #Create config file if not present
    if(! (Test-Path -Path $global:maad_config_path)){
        $maad_config = ([PSCustomObject]@{
            "tor_config" = @{
                tor_root_directory = "C:/Users/username/sub_folder/Tor Browser"
                tor_host = "127.0.0.1"
                tor_port = "9150"
                control_port = "9151"
            }
            "DependecyCheckBypass" = $false
        })
        $maad_config_json = $maad_config | ConvertTo-Json
        $maad_config_json | Set-Content -Path $global:maad_config_path -Force
    }
}


function InitializationChecks{  
    if((($PSVersionTable).PSVersion.Major) -ne 5){
        MAADWriteError "Incompatible PS Version -> $($PSVersionTable.PSVersion.Major)"
        MAADWriteInfo "Switch to execute MAAD-AF in PowerShell 5"
        MAADPause
    }

    #Create outputs & local files directory (if not present)
    CreateLocalDir
    CreateOutputsDir

    #Clear any active sessions to prevent reaching session limit
    ClearActiveSessions 

    #Log MAAD-AF start
    Write-MAADLog "Start" "MAAD-AF Initialized"
}

function EnterMailbox ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options.If valid, returns mailbox address($input_mailbox_address)
    $repeat = $false
    do {
        $input_mailbox_address = Read-Host -Prompt $input_prompt

        if ($input_mailbox_address.ToUpper() -eq "RECON" -or $input_mailbox_address -eq "" -or $input_mailbox_address -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching Mailboxes"
                $all_mailboxes = Get-Mailbox | Select-Object DisplayName, PrimarySmtpAddress 
                
                Show-MAADOptionsView -OptionsList $all_mailboxes -NewWindowMessage "Mailboxes in tenant"
                
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to find mailboxes"
                $repeat = $false
            }
        }
        else {
            ValidateMailbox($input_mailbox_address)
            if ($global:mailbox_found -eq $true) {
                $repeat = $false
            }
            if ($global:mailbox_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true) 
}

function ValidateMailbox ($input_mailbox_address){
    ###This function returns if a mailbox address is valid ($mailbox_found = $true) or not ($mailbox_found = $false)
    $global:mailbox_found = $false
    Write-Host ""

    try {
        $fetch_mailbox = Get-Mailbox -Identity $input_mailbox_address -ErrorAction Stop
        $global:mailbox_address = $input_mailbox_address
        $global:mailbox_found = $true
        MAADWriteProcess "Mailbox Found : $global:mailbox_address"
    }
    catch {
        MAADWriteError "Mailbox Not Found"
        $global:mailbox_found = $false
    }
}

function EnterAccount ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns account name($account_username)
    $repeat = $false
    do {
        $input_user_account = Read-Host -Prompt $input_prompt

        if ($input_user_account.ToUpper() -eq "RECON" -or $input_user_account -eq "" -or $input_user_account -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching Accounts"
                #Get-AzureADUser -All $true | Format-Table -Property DisplayName,UserPrincipalName,UserType
                $all_users = Get-AzureADUser -All $true | Select-Object DisplayName,UserPrincipalName,UserType
                Show-MAADOptionsView -OptionsList $all_users -NewWindowMessage "Accounts in tenant"
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to find account"
                $repeat = $false
            }
        }
        else {
            ValidateAccount($input_user_account)
            if ($global:account_found -eq $true) {
                $repeat = $false
            }
            if ($global:account_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateAccount ($input_user_account){
    ###This function returns if an account exists in Azure AD ($account_found = $true) or not ($account_found = $false)
    $global:account_found = $false
    Write-Host ""

    $check_account = Get-AzureADUser -SearchString $input_user_account
    
    if ($check_account -eq $null){
        MAADWriteError "Account Not Found"
        $global:account_found = $false
    }
    
    else {
        if ($check_account.GetType().BaseType.Name -eq "Array"){
            MAADWriteError "Recon -> Multiple accounts found matching term"
            MAADWriteInfo "Lets take it slow ;) Try more specific search to target one account"

            Read-Host "`n[?] Press enter to view all matched accounts"
            Write-Host ""
            $check_account | Format-Table -Property UserPrincipalName, ObjectId -AutoSize
            $global:account_found = $false
        }
        else {
            $global:account_username = $check_account.UserPrincipalName
            $global:account_found = $true
            MAADWriteProcess "Account Found : $global:account_username"
        }
    }
}

function EnterGroup ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns group name($group_name)
    $repeat = $false
    do {
        $input_group = Read-Host -Prompt $input_prompt

        if ($input_group.ToUpper() -eq "RECON" -or $input_group -eq "" -or $input_group -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching Groups"
                # Get-AzureADMSGroup | Format-Table -Property DisplayName
                $all_groups = Get-AzureADMSGroup | Select-Object DisplayName
                Show-MAADOptionsView -OptionsList $all_groups -NewWindowMessage "Groups in tenant"
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to find groups"
                $repeat = $false
            }
        }
        else {
            ValidateGroup($input_group)
            if ($global:group_found -eq $true) {
                $repeat = $false
            }
            if ($global:group_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateGroup ($input_group){
    ###This function returns if a group exists in Azure AD ($group_found = $true) or not ($group_found = $false)
    $global:group_found = $false
    Write-Host ""

    $check_group = Get-AzureADMSGroup -SearchString $input_group
    
    if ($check_group -eq $null){
        MAADWriteError "Group Not Found"
        $global:group_found = $false
    }
    
    else {
        if ($check_group.GetType().BaseType.Name -eq "Array"){
            MAADWriteProcess "Recon -> Multiple groups found matching term"
            MAADWriteInfo "Lets take things slow ;) Be more specific to target one group"

            Read-Host "`n[?] Press enter to view all matched groups"
            Write-Host ""
            $check_group | Format-Table -Property DisplayName, Id -AutoSize
            $global:group_found = $false
        }
        else {
            $global:group_name = $check_group.DisplayName
            $global:group_found = $true
            MAADWriteProcess "Group Found : $global:group_name"
        }
    }
}


function EnterRole ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns role name($input_role)
    $repeat = $false
    do {
        $input_role = Read-Host -Prompt $input_prompt

        if ($input_role.ToUpper() -eq "RECON" -or $input_role -eq "" -or $input_role -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching Roles"
                # Get-AzureADMSRoleDefinition | Format-Table -Property DisplayName,Description
                $all_roles = Get-AzureADMSRoleDefinition | Select-Object DisplayName,Description
                Show-MAADOptionsView -OptionsList $all_roles -NewWindowMessage "Roles in tenant"
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to find role"
                $repeat = $false
            }
        }
        else {
            ValidateRole($input_role)
            if ($global:role_found -eq $true) {
                $repeat = $false
            }
            if ($global:role_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateRole ($input_role){
    ###This function returns if a group exists in Azure AD ($role_found = $true) or not ($role_found = $false)
    $global:role_found = $false
    Write-Host ""

    $check_role = Get-AzureADMSRoleDefinition  -Filter "startswith(displayName, '$input_role')"
    
    if ($check_role -eq $null){
        MAADWriteError "Role Not Found"
        $global:role_found = $false
    }
    
    else {
        if ($check_role.GetType().BaseType.Name -eq "Array"){
            MAADWriteError "Recon -> Multiple roles found matching term"
            MAADWriteInfo "Lets take things slow ;) Be more specific to target one role!"

            Read-Host "`n[?] Press enter to view all mathced roles"
            Write-Host ""
            $check_role | Format-Table -Property DisplayName, Id -AutoSize
            $global:role_found = $false
        }
        else {
            $global:role_name = $check_role.DisplayName
            $global:role_found = $true
            MAADWriteProcess "Role Found : $global:role_name"
        }
    }
}

function EnterManagementRole ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns role name($management_role_name)
    $repeat = $false
    do {
        $input_mgmt_role = Read-Host -Prompt $input_prompt

        if ($input_mgmt_role.ToUpper() -eq "RECON" -or $input_mgmt_role -eq "" -or $input_mgmt_role -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching Management Roles"
                # Get-RoleGroup | Format-Table -Property Name, Description
                $all_role_groups = Get-RoleGroup | Select-Object Name, Description
                Show-MAADOptionsView -OptionsList $all_role_groups -NewWindowMessage "Management Roles in tenant"
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to find management role"
                $repeat = $false
            }
        }
        else {
            ValidateManagementRole($input_mgmt_role)
            if ($global:mgmt_role_found -eq $true) {
                $repeat = $false
            }
            if ($global:mgmt_role_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateManagementRole ($input_mgmt_role){
    ###This function returns if a group exists in Azure AD ($mgmt_role_found = $true) or not ($mgmt_role_found = $false)
    $global:mgmt_role_found = $false
    Write-Host ""

    $check_mgmt_role = Get-RoleGroup -Filter "Name -eq '$input_mgmt_role'"
    
    if ($check_mgmt_role -eq $null){
        MAADWriteError "Management role Not Found"
        $global:mgmt_role_found = $false
    }
    
    else {
        if ($check_mgmt_role.GetType().BaseType.Name -eq "Array"){
            MAADWriteError "Recon -> Multiple management roles found matching term"
            MAADWriteInfo "Lets take things slow ;) Be more specific to target one role"

            Read-Host "`n[?] Press enter to view all mathced management roles"
            Write-Host ""
            $check_mgmt_role | Format-Table -Property Name, Description -AutoSize
            $global:mgmt_role_found = $false
        }
        else {
            $global:management_role_name = $check_mgmt_role.Name
            $global:mgmt_role_found = $true
            MAADWriteProcess "Management role Found : $global:management_role_name"
        }
    }
}

function EnterTeam ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns team name($input_team)
    $repeat = $false
    do {
        $input_team = Read-Host -Prompt $input_prompt

        if ($input_team.ToUpper() -eq "RECON" -or $input_team -eq "" -or $input_team -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching Teams"
                # Get-Team | Format-Table DisplayName,GroupID,Description,Visibility
                $all_teams = Get-Team | Select-Object DisplayName,GroupID,Description,Visibility
                Show-MAADOptionsView -OptionsList $all_teams -NewWindowMessage "Teams in tenant"
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to find teams"
                $repeat = $false
            }
        }
        else {
            ValidateTeam($input_team)
            if ($global:team_found -eq $true) {
                $repeat = $false
            }
            if ($global:team_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateTeam ($input_team){
    ###This function returns if a group exists in Azure AD ($team_found = $true) or not ($team_found = $false)
    $global:team_found = $false
    Write-Host ""

    $check_team = Get-Team -DisplayName $input_team
    
    if ($check_team -eq $null){
        MAADWriteError "Team Not Found"
        $global:team_found = $false
    }
    
    else {
        if ($check_team.GetType().BaseType.Name -eq "Array"){
            MAADWriteError "Recon -> Multiple teams found matching term" 
            MAADWriteInfo "Lets take things slow ;) Be more specific to target one team"

            Read-Host "`n[?] Press enter to view all matched teams"
            Write-Host ""
            $check_team | Format-Table -Property DisplayName, GroupID -AutoSize
            $global:team_found = $false
        }
        else {
            $global:team_name = $check_team.DisplayName
            $global:team_found = $true
            MAADWriteProcess "Team Found : $global:team_name"
        }
    }
}

function EnterApplication ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns role name($input_application)
    $repeat = $false
    do {
        $input_application = Read-Host -Prompt $input_prompt

        if ($input_application.ToUpper() -eq "RECON" -or $input_application -eq "" -or $input_application -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching Applications"
                # Get-AzureADApplication | Format-Table -Property DisplayName, AppId, ObjectId, Description
                $all_apps = Get-AzureADApplication | Select-Object DisplayName, AppId, ObjectId
                Show-MAADOptionsView -OptionsList $all_apps -NewWindowMessage "Applications in tenant"
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to find applications"
                $repeat = $false
            }
        }
        else {
            ValidateApplication($input_application)
            if ($global:application_found -eq $true) {
                $repeat = $false
            }
            if ($global:application_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateApplication ($input_application){
    ###This function returns if a group exists in Azure AD ($application_found = $true) or not ($application_found = $false)
    $global:application_found = $false
    Write-Host ""

    $check_application = Get-AzureADApplication  -SearchString $input_application
    
    if ($check_application -eq $null){
        MAADWriteError "Application Not Found"
        $global:application_found = $false
    }
    
    else {
        if ($check_application.GetType().BaseType.Name -eq "Array"){
            MAADWriteError "Recon -> Multiple applications found matching your term"
            MAADWriteInfo "Lets take things slow ;) Be more specific to target one application"

            Read-Host "`n[?] Press enter to view all matched applications"
            Write-Host ""
            $check_application | Format-Table -Property DisplayName, AppId, ObjectId -AutoSize -Wrap
            $global:application_found = $false
        }
        else {
            $global:application_name = $check_application.DisplayName
            $global:application_found = $true
            MAADWriteProcess "Application Found : $global:application_name"
        }
    }
}

function EnterSharepointSite ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns role name($input_site)
    $repeat = $false
    do {
        $input_site = (Read-Host -Prompt $input_prompt).Trim()

        if ($input_site.ToUpper() -eq "RECON" -or $input_site -eq "" -or $input_site -eq $null) {
            try {
                Write-Host ""
                MAADWriteProcess "Recon -> Searching SharePoint Sites"
                # Get-SPOSite | Format-Table -Property Title,URL,SharingCapability,ConditionalAccessPolicy 
                $all_sites = Get-SPOSite | Select-Object Title,URL,SharingCapability 
                Show-MAADOptionsView -OptionsList $all_sites -NewWindowMessage "SP Sites in tenant"
                $repeat = $true
            }
            catch {
                MAADWriteError "Failed to list SharePoint sites"
                $repeat = $false
            }
        }
        else {
            ValidateSharepointSite($input_site)
            if ($global:site_found -eq $true) {
                $repeat = $false
            }
            if ($global:site_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateSharepointSite ($input_site){
    ###This function returns if a group exists in Azure AD ($site_found = $true) or not ($site_found = $false)
    $global:site_found = $false
    Write-Host ""

    $check_site = Get-SPOSite | ?{$_.Title -eq $input_site}
    
    if ($check_site -eq $null){
        MAADWriteError "Site Not Found"
        $global:site_found = $false
    }
    
    else {
        if ($check_site.GetType().BaseType.Name -eq "Array"){
            MAADWriteError "Recon -> Multiple sites found matching your term" 
            MAADWriteInfo "Lets take things slow ;) Be more specific to target one site"

            Read-Host "`n[?] Press enter to view all matched sites"
            Write-Host ""
            $check_site | Format-Table -Property Title, URL -AutoSize
            $global:site_found = $false
        }
        else {
            $global:sharepoint_site_name = $check_site.Title
            $global:sharepoint_site_url = $check_site.URL
            $global:site_found = $true
            MAADWriteProcess "Site Found : $global:sharepoint_site_name"
        }
    }
}

Function Write-MAADLog([string]$event_type, [String]$event_message ) {
    #Acceptable event types: START, END, SUCCESS, ERROR, INFO
    
    #Get log time stamp
    $event_time = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss:fff tt")
    #Craft log message
    $log_message = "$event_time - [$($event_type.ToUpper())] - $event_message"
    #Write log
    Add-Content -Value $log_message -Path $global:maad_log_file 
}

function MAADHelp {
    $maad_commands = [ordered]@{
        "SHOW ALL" = "Expand all options in MAAD Attack Arsenal for a full list of options.";
        "ADD CREDS" = "Add new credentials to the MAAD-AF credentials store for quickly establishing access later.";
        "SHOW CREDS" = "Show all credentials collected in MAAD-AF credentials store.";
        "ESTABLISH ACCESS" = "Initiate access attempt to Micrsoft services using stored or new credentials.";
        "SWITCH ACCESS" = "Use another credential from Credential Store to establish access in modules"
        "ACCESS INFO" = "Display details about my current access session";
        "KILL ACCESS" = "Terminate all active connections";
        "ANONYMIZE" = "Enable TOR";
        "EXIT" = "Exit MAAD-AF without closing active access connections.";
        "FULL EXIT" = "Exit MAAD-AF and close all active connections."
    }

    #Display commands
    Write-Host ""
    DisplayCentre "##########################" "Red"
    DisplayCentre "MAAD-AF Help" "Red"
    DisplayCentre "##########################" "Red"
    Write-Host "`nExecute module"
    Write-Host "Select an option from the MAAD Attack Arsenal menu by typing the option number (eg: 1 for Pre-Attack)"

    Write-Host "`nQuick Command"
    Write-Host "Take quick actions using a quick action command in MAAD Atack Arsenal menu"

    #$maad_commands |Format-Table -HideTableHeaders -Wrap
    $maad_commands | Format-Table @{Label="Quick Command";Expression={$tf = "91"; $e = [char]27; "$e[${tf}m$($_.Name)${e}[0m"}}, @{Label="Description";Expression={$tf = "0"; $e = [char]27; "$e[${tf}m$($_.Value)${e}[0m"}} -Wrap

    MAADPause
}

function MAADWriteSuccess ([string]$message) {
    Write-Host "[+] Success -> $message" -ForegroundColor Yellow
}

function MAADWriteProcess ([string]$message) {
    Write-Host "[*] $message" -ForegroundColor Gray
    Start-Sleep -Seconds 1
}

function MAADWriteInfo ([string]$message) {
    Write-Host "[i] $message" -ForegroundColor Cyan
}

function MAADWriteError ([string]$message) {
    Write-Host "[x] $message" -ForegroundColor Red
}

function MAADPause {
    Write-Host ""
    Read-Host -Prompt "[?] Continue"
}

function Show-MAADOutput {
    param (
        [int]$large_limit,
        [array]$output_list,
        [string]$file_path
    )
    #This function displays a large output in a new powershell window
    MAADWriteProcess "Found $($output_list.Count) results"

    if ($output_list.Count -gt 0) {
        
        MAADWriteProcess "Exporting results"
        $output_time_stamp = Get-Date -Format "MMM dd yyyy HH:mm:ss"
        "`n$output_time_stamp `n--------------------" | Out-File -FilePath $file_path -Append
        $output_list | Out-File -FilePath $file_path -Append -Width 10000
        MAADWriteProcess "Output Saved -> $file_path"

        if ($output_list.Count -gt $large_limit) {
            $user_input = Read-Host "`n[?] Display full results (y/n)"
            Write-Host ""
            if ($user_input -eq "y"){
                MAADWriteInfo "Large output"
                MAADWriteProcess "Checkout results in -> MAAD-AF Output view"
                
                $script = {
                    $name = 'MAAD-AF Output View'
                    $host.ui.RawUI.WindowTitle = $name
                }
                Start-Process powershell -ArgumentList "-NoExit $script `"Get-Content -Path $file_path; Read-Host `"Press [enter] to exit`" ;exit`""
            }
        }
        else {
            MAADWriteProcess "Checkout results in -> MAAD-AF Output view"
            Start-Process powershell -ArgumentList "-NoExit $script `"Get-Content -Path $file_path; Read-Host `"Press [enter] to close output view`" ;exit`""
        }
    }
}

function Show-MAADOptionsView {
    param (
        [array]$OptionsList,
        [string]$NewWindowMessage
    )
    #This function displays options in a new powershell windows

    $temp_file = New-TemporaryFile

    if ($OptionsList.Count -gt 0) {
        $NewWindowMessage | Out-File -FilePath $temp_file
        $OptionsList | Out-File -FilePath $temp_file -Width 10000 -Append
        
        MAADWriteInfo "Select from options in Options View"

        $script = {
            $host.ui.RawUI.WindowTitle = 'MAAD-AF Options View'
        }
        Start-Process powershell -ArgumentList "-NoExit $script `"Get-Content -Path $temp_file; Read-Host `"Press [enter] to close options view`" ;exit`""
    }
}