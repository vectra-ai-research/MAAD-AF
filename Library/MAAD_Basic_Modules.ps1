###Basic functions
function RequiredModules {
    ###This function checks for required modules by MAAD and Installs them if unavailable. Some modules have specific version requirements specified in the dictionary values
    $RequiredModules=@{"Az.Accounts" = "2.13.1";"Az.Resources" = "6.11.2"; "AzureAd" = "2.0.2.182";"MSOnline" = "1.1.183.80";"ExchangeOnlineManagement" = "3.2.0";"MicrosoftTeams" = "5.7.0";"AADInternals" = "0.9.2";"Microsoft.Online.SharePoint.PowerShell" = "16.0.23710.12000";"PnP.PowerShell" = "1.12.0";"Microsoft.Graph.Identity.SignIns" = "2.6.1";"Microsoft.Graph.Applications" = "2.6.1";"Microsoft.Graph.Users" = "2.6.1";"Microsoft.Graph.Groups" = "2.6.1"}
    $missing_modules = @{}
    $installed_modules = @{}

    #Check for available modules
    Write-Host "`nChecking dependencies..."
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
        Write-Host "All required modules available! `n" -ForegroundColor Gray
        Write-Host "Continuing..."
        $allow = $null
    }
    elseif ($installed_modules_count -lt $RequiredModules.Count) {
        Write-Host "`n$installed_modules_count / $($RequiredModules.Count) modules currently installed" -ForegroundColor Gray

        Write-Host "`nMAAD-AF requires the following missing powershell modules:`n$($missing_modules.Keys)" -ForegroundColor Gray
        $allow = Read-Host -Prompt "`nAutomatically install missing modules? (Yes / No)"
    
        if ($null -eq $allow) {
            #Do nothing
        }
        elseif ($allow -notin "No","no","N","n") {
            Write-Host "Installing missing modules..." -ForegroundColor Gray

            Set-ExecutionPolicy Unrestricted -Force
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

            #Install missing modules
            foreach ($module in $missing_modules.Keys){
                Write-Host "'$module' module does not exist. Installing it now..." -ForegroundColor Gray
                try {
                    if ($missing_modules[$module] -eq "") {
                        Install-Module -Name $module -Confirm:$False -WarningAction SilentlyContinue -ErrorAction Stop
                        #Add module to installed modules dict
                        $installed_modules[$module] = $RequiredModules[$module]
                        Write-Host "Successfully installed module $module" -ForegroundColor Yellow
                    }
                    else {
                        Install-Module -Name $module -RequiredVersion $missing_modules[$module] -Confirm:$False -WarningAction SilentlyContinue -ErrorAction Stop
                        $installed_modules[$module] = $RequiredModules[$module]
                        Write-Host "Successfully installed module $module" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Host "Failed to install. Skippig module: $module. " -ForegroundColor Red
                }   
            }
        }
        else {
            Write-Host "Note: Some MAAD-AF functions may fail if required modules are missing" -ForegroundColor Gray
        } 
    }

    Write-Host " $($installed_modules.Count) / $($RequiredModules.Count) modules installed!" -ForegroundColor Gray

    #Import all installed Modules
    Write-Host "`nImporting installed modules to current run space..." -ForegroundColor Gray
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
            Write-Host "Failed to import. Skippig module: $module . " -ForegroundColor Red
        }
    }       

    Write-Host "Modules check completed" -ForegroundColor Gray
    #Prevents overwrite from any imported modules 
    $host.UI.RawUI.WindowTitle = "MAAD Attack Framework"
    Write-MAADLog "info" "Modules check completed"
} 

function ClearActiveSessions {
    Get-PSSession | Remove-PSSession
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
    Write-Host "`n$menu_message" -ForegroundColor Red
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
        })
        $maad_config_json = $maad_config | ConvertTo-Json
        $maad_config_json | Set-Content -Path $global:maad_config_path -Force
    }
}

function InitializationChecks{  
    if((($PSVersionTable).PSVersion.Major) -ne 5){
        Write-Host "`nMAAD-AF is most compatible with PowerShell version 5" -ForegroundColor Red
        Write-Host "Some features might fail. You are currently running: $($PSVersionTable.PSVersion.Major)" -ForegroundColor Gray
        Write-Host "If possible, switch to running MAAD-AF in PowerShell 5" -ForegroundColor Gray
        Pause
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
                Write-Host "`nExecuting recon to list available mailboxes in the environment" -ForegroundColor Gray
                Get-Mailbox | Format-Table -Property DisplayName,PrimarySmtpAddress 
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find mailboxes" -ForegroundColor Red
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
    try {
        Get-Mailbox -Identity $input_mailbox_address -ErrorAction Stop
        $global:mailbox_address = $input_mailbox_address
        $global:mailbox_found = $true
        Write-Host "Mailbiox found: $global:mailbox_address`n" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`nThe mailbox does not exist or the account does not have a mailbox setup.`n" -ForegroundColor Red
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
                Write-Host "`nExecuting recon to list available accounts in the tenant" -ForegroundColor Gray
                Get-AzureADUser -All $true | Format-Table -Property DisplayName,UserPrincipalName,UserType
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find account" -ForegroundColor Red
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

    $check_account = Get-AzureADUser -SearchString $input_user_account
    
    if ($check_account -eq $null){
        Write-Host "The account does not exist or match an account in the tenant!`n" -ForegroundColor Red
        $global:account_found = $false
    }
    
    else {
        if ($check_account.GetType().BaseType.Name -eq "Array"){
            Write-Host "Multiple accounts found matching your search. Lets take things slow ;) Be more specific to target one account!" -ForegroundColor Red

            Write-Host "Here are the multiple matching accounts:`n" -ForegroundColor Gray
            foreach ($account in $check_account){
                Write-Host "$($account.UserPrincipalName) : $($group.ObjectId)" -ForegroundColor Gray
            }
            Write-Host ""
            $global:account_found = $false
        }
        else {
            $global:account_username = $check_account.UserPrincipalName
            $global:account_found = $true
            Write-Host "Account found: $global:account_username`n" -ForegroundColor Yellow
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
                Write-Host "`nExecuting recon to list available groups in the tenant" -ForegroundColor Gray
                Get-AzureADMSGroup | Format-Table -Property DisplayName
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find group" -ForegroundColor Red
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

    $check_group = Get-AzureADMSGroup -SearchString $input_group
    
    if ($check_group -eq $null){
        Write-Host "The group does not exist or matches any group in the tenant!`n" -ForegroundColor Red
        $global:group_found = $false
    }
    
    else {
        if ($check_group.GetType().BaseType.Name -eq "Array"){
            Write-Host "`nMultiple groups found matching your term. Lets take things slow ;) Be more specific to target one group!" -ForegroundColor Red

            Write-Host "Here are the multiple matching groups:`n" -ForegroundColor Gray
            foreach ($group in $check_group){
                Write-Host "$($group.DisplayName) : $($group.Id)" -ForegroundColor Gray
            }
            Write-Host ""
            $global:group_found = $false
        }
        else {
            $global:group_name = $check_group.DisplayName
            $global:group_found = $true
            Write-Host "Group found: $global:group_name`n" -ForegroundColor Yellow
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
                Write-Host "`nExecuting recon to list available roles in the tenant" -ForegroundColor Gray
                Get-AzureADMSRoleDefinition | Format-Table -Property DisplayName,Description
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find role" -ForegroundColor Red
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

    #$check_role = Get-AzureADMSRoleDefinition -SearchString $input_role
    $check_role = Get-AzureADMSRoleDefinition  -Filter "startswith(displayName, '$input_role')"
    
    if ($check_role -eq $null){
        Write-Host "The role does not exist or matches any other role in the tenant!`n" -ForegroundColor Red
        $global:role_found = $false
    }
    
    else {
        if ($check_role.GetType().BaseType.Name -eq "Array"){
            Write-Host "`nMultiple roles found matching your term. Lets take things slow ;) Be more specific to target one role!" -ForegroundColor Red

            Write-Host "Here are the multiple matching roles:`n" -ForegroundColor Gray
            foreach ($role in $check_role){
                Write-Host "$($role.DisplayName) : $($role.Id)" -ForegroundColor Gray
            }
            Write-Host ""
            $global:role_found = $false
        }
        else {
            $global:role_name = $check_role.DisplayName
            $global:role_found = $true
            Write-Host "Role found: $global:role_name`n" -ForegroundColor Yellow
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
                Write-Host "`nExecuting recon to list management roles in the tenant" -ForegroundColor Gray
                Get-RoleGroup | Format-Table -Property Name, Description
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find role" -ForegroundColor Red
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

    $check_mgmt_role = Get-RoleGroup -Filter "Name -eq '$input_mgmt_role'"
    
    if ($check_mgmt_role -eq $null){
        Write-Host "The role does not exist or matches any other role in the tenant!`n" -ForegroundColor Red
        $global:mgmt_role_found = $false
    }
    
    else {
        if ($check_mgmt_role.GetType().BaseType.Name -eq "Array"){
            Write-Host "`nMultiple roles found matching your term. Lets take things slow ;) Be more specific to target one role!" -ForegroundColor Red

            Write-Host "Here are the multiple matching roles:`n" -ForegroundColor Gray
            foreach ($role in $check_mgmt_role){
                Write-Host "$($role.Name) : $($role.Description)" -ForegroundColor Gray
            }
            Write-Host ""
            $global:mgmt_role_found = $false
        }
        else {
            $global:management_role_name = $check_mgmt_role.Name
            $global:mgmt_role_found = $true
            Write-Host "Role found: $global:management_role_name`n" -ForegroundColor Yellow
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
                Write-Host "`nExecuting recon to list available teams in the tenant" -ForegroundColor Gray
                Get-Team | Format-Table DisplayName,GroupID,Description,Visibility
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find team" -ForegroundColor Red
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

    $check_team = Get-Team -DisplayName $input_team
    
    if ($check_team -eq $null){
        Write-Host "The team does not exist or matches any other team in the tenant!`n" -ForegroundColor Red
        $global:team_found = $false
    }
    
    else {
        if ($check_team.GetType().BaseType.Name -eq "Array"){
            Write-Host "`nMultiple teams found matching your term. Lets take things slow ;) Be more specific to target one team!" -ForegroundColor Red

            Write-Host "Here are the multiple matching teams:`n" -ForegroundColor Gray
            foreach ($team in $check_team){
                Write-Host "$($team.DisplayName) : $($team.GroupID)" -ForegroundColor Gray
            }
            Write-Host ""
            $global:team_found = $false
        }
        else {
            $global:team_name = $check_team.DisplayName
            $global:team_found = $true
            Write-Host "Team found: $global:team_name`n" -ForegroundColor Yellow
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
                Write-Host "`nExecuting recon to list available applications in the tenant" -ForegroundColor Gray
                Get-AzureADApplication | Format-Table -Property DisplayName, AppId, ObjectId, Description
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find application" -ForegroundColor Red
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

    #$check_application = Get-AzureADMSRoleDefinition -SearchString $input_application
    $check_application = Get-AzureADApplication  -SearchString $input_application
    
    if ($check_application -eq $null){
        Write-Host "The application does not exist or matches any other application in the tenant!`n" -ForegroundColor Red
        $global:application_found = $false
    }
    
    else {
        if ($check_application.GetType().BaseType.Name -eq "Array"){
            Write-Host "`nMultiple applications found matching your term. Lets take things slow ;) Be more specific to target one application!" -ForegroundColor Red

            Write-Host "Here are the multiple matching applications:`n" -ForegroundColor Gray
            foreach ($application in $check_application){
                Write-Host "$($application.DisplayName) : $($application.ObjectId)" -ForegroundColor Gray
            }
            Write-Host ""
            $global:application_found = $false
        }
        else {
            $global:application_name = $check_application.DisplayName
            $global:application_found = $true
            Write-Host "Application found: $global:application_name`n" -ForegroundColor Yellow
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
                Write-Host "`nExecuting recon to list all SharePoint sites in the tenant" -ForegroundColor Gray
                Get-SPOSite | Format-Table -Property Title,URL,SharingCapability,ConditionalAccessPolicy 
                $repeat = $true
            }
            catch {
                Write-Host "Failed to list SharePoint sites" -ForegroundColor Red
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

    $check_site = Get-SPOSite | ?{$_.Title -eq $input_site}
    
    if ($check_site -eq $null){
        Write-Host "The site does not exist or matches any other site in the tenant!`n" -ForegroundColor Red
        $global:site_found = $false
    }
    
    else {
        if ($check_site.GetType().BaseType.Name -eq "Array"){
            Write-Host "`nMultiple sites found matching your term. Lets take things slow ;) Be more specific to target one site!" -ForegroundColor Red

            Write-Host "Here are the multiple matching sites:`n" -ForegroundColor Gray
            foreach ($site in $check_site){
                Write-Host "$($site.Title) : $($site.URL)" -ForegroundColor Gray
            }
            Write-Host ""
            $global:site_found = $false
        }
        else {
            $global:sharepoint_site_name = $check_site.Title
            $global:sharepoint_site_url = $check_site.URL
            $global:site_found = $true
            Write-Host "Site found: $global:sharepoint_site_name`n" -ForegroundColor Yellow
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
        "EXECUTE RECON" = "Gather all information from the environment using the current access and MAAD-AF reconnaissance modules";
        "EXIT" = "Exit MAAD-AF without closing active access connections.";
        "FULL EXIT" = "Exit MAAD-AF and close all active access connections."
    }

    #Display commands
    Write-Host "`nSelect an option from the attack arsenal by entering the option name or choose from one of the shotcut keywords below" -ForegroundColor Gray
    $maad_commands |Format-Table -HideTableHeaders -Wrap
    Pause
}