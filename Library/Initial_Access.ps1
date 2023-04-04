function establish_connection {
    #Setting all variables as $null
    $global:AdminUsername, $global:AdminPassword, $global:AccessToken, $global:AdminCredential = $null
    Write-Host ""
    #Checking if saved credentials are available in MAAD_Config.ps1
    if ($global:CredentialsList.Count -gt 0) {
        Write-Host "Credentials available:" -ForegroundColor Gray
        foreach ($item in $global:CredentialsList){
            Write-Host $global:CredentialsList.IndexOf($item) ":" $item["username"] -ForegroundColor Gray
        }
        $credential_choice = Read-Host "`nChoose a credential from the list or enter 'x' to enter new credentials manually"

        try {
            $credential_choice = [int]$credential_choice
            if ($credential_choice -lt $global:CredentialsList.Count) {
                Write-Host $global:CredentialsList[$credential_choice]["username"]
                $global:AdminUsername = $global:CredentialsList[$credential_choice]["username"]
                $global:AdminPassword = $global:CredentialsList[$credential_choice]["password"]
                $global:AccessToken = $global:CredentialsList[$credential_choice]["token"]
            }
        }
        catch {
            #Do Nothing
        }
    }

    #Get credentials if not found in config file
    if ($global:AdminUsername -in $null,"" -or $global:AdminPassword -in "",$null) {
        Write-Host "`nEnter admin credentials to access Azure AD & M365 environment" -ForegroundColor Red
        $global:AdminUsername = Read-Host -Prompt "Enter admin username:"
        $global:AdminSecurePass = Read-Host -Prompt "Enter $global:AdminUsername password:" -AsSecureString 
        $global:AdminCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($global:AdminUsername, $global:AdminSecurePass)
        Write-Host "`nTip: You can also store credentials in MAAD_Config.ps1 if you would like to." -ForegroundColor Gray
    }
    else {
        Write-Host "Retrieved credentials...`n"
        $global:AdminSecurePass = ConvertTo-SecureString $global:AdminPassword -AsPlainText -Force
        $global:AdminCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($global:AdminUsername, $global:AdminSecurePass)
    }

    #Create Sessions
    Write-Host "`nHold tight!!! Establishing access to Azure AD and M365 services..." -ForegroundColor Yellow -BackgroundColor Black
    AccessAzureAD $global:AdminUsername $global:AdminCredential $global:AccessToken
    AccessAzAccount $global:AdminUsername $global:AdminCredential $global:AccessToken
    AccessTeams $global:AdminUsername $global:AdminCredential $global:AccessToken
    AccessExchangeOnline $global:AdminUsername $global:AdminCredential $global:AccessToken
    AccessMsol $global:AdminUsername $global:AdminCredential $global:AccessToken
    AccessSharepoint $global:AdminUsername $global:AdminCredential $global:AccessToken
    AccessSharepointAdmin $global:AdminUsername $global:AdminCredential $global:AccessToken
}

function AccessAzureAD{
    param (
        [Parameter(Mandatory)]$AdminUsername,
        [Parameter(Mandatory)][PSCredential] $AdminCredential,
        $AccessToken
    )
    ###Connect Azure AD 
    if ($AccessToken -notin "",$null ) {
        try {
        #Attempt token authentication  
        Connect-AzureAD -AadAccessToken $AccessToken -AccountId $AdminUsername -ErrorAction Stop | Out-Null
        Write-Host "[.]Established access to AzureAD`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Token authentication failed. Attempting basic authentication now..."
            try {
                #Attempt basic authentication
                Connect-AzureAD -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                Write-Host "[.]Established access to AzureAD`n" -ForegroundColor Yellow
            }
            catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-AzureAD -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to AzureAD`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "Failed to establish access to AzureAD. Validate credentials!`n" -ForegroundColor Red
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-AzureAD -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            Write-Host "[.]Established access to AzureAD`n" -ForegroundColor Yellow  
        }
        catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-AzureAD -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to AzureAD`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                Write-Host "Invalid credentials!`n" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to establish access to AzureAD. Validate credentials!`n" -ForegroundColor Red
        }
    }
}

function AccessAzAccount {
    param (
        [Parameter(Mandatory)]$AdminUsername,
        [Parameter(Mandatory)][PSCredential] $AdminCredential,
        $AccessToken
    )
    ###Connect AzAccount
    if ($AccessToken -notin "",$null ) {
        try {
        #Attempt token authentication  
        Connect-AzAccount -AccessToken $AccessToken -AccountId $AdminUsername -ErrorAction Stop | Out-Null
        Write-Host "[.]Established access to Az`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Token authentication failed. Attempting basic authentication now..."
            try {
                #Attempt basic authentication
                Connect-AzAccount -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                Write-Host "[.]Established access to Az`n" -ForegroundColor Yellow
            }
            catch [Microsoft.Azure.Commands.Common.Exceptions.AzPSAuthenticationFailedException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-AzAccount -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to Az`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n`n" -ForegroundColor Red
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    Write-Host "Invalid credentials!`n`n" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "Failed to establish access to Az. Validate credentials!`n" -ForegroundColor Red
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-AzAccount -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            Write-Host "[.]Established access to Az`n" -ForegroundColor Yellow
        }
        catch [Microsoft.Azure.Commands.Common.Exceptions.AzPSAuthenticationFailedException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-AzAccount -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to Az`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n`n" -ForegroundColor Red
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password`n" -InputObject $_.Exception.Message)) {
                Write-Host "Invalid credentials!`n`n" -ForegroundColor Red
            }
        }
        catch {
            $_
            Write-Host "Failed to establish access to Az. Validate credentials!`n" -ForegroundColor Red
        }
    }
}

function AccessTeams {
    param (
        [Parameter(Mandatory)]$AdminUsername,
        [Parameter(Mandatory)][PSCredential] $AdminCredential,
        $AccessToken
    )
    ###Connect Teams
    if ($AccessToken -notin "",$null ) {
        try {
        #Attempt token authentication  
        Connect-MicrosoftTeams -AadAccessToken $AccessToken -AccountId $AdminUsername -ErrorAction Stop | Out-Null
        Write-Host "[.]Established access to Teams`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Token authentication failed. Attempting basic authentication now..."
            try {
                #Attempt basic authentication
                Connect-MicrosoftTeams -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                Write-Host "[.]Established access to Teams`n" -ForegroundColor Yellow
            }
            catch [System.AggregateException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to Teams`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    $null = Read-Host "Exiting tool now!!!"
                    exit
                }
            }
            catch {
                Write-Host "Failed to establish access to AzureAD. Validate credentials!`n" -ForegroundColor Red
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-MicrosoftTeams -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            Write-Host "[.]Established access to Teams`n" -ForegroundColor Yellow  
        }
        catch [System.AggregateException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to Teams`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                Write-Host "Invalid credentials!`n" -ForegroundColor Red
                $null = Read-Host "Exiting tool now!!!"
                exit
            }
        }
        catch {
            Write-Host "Failed to establish access to Teams. Validate credentials!`n" -ForegroundColor Red
        }       
    }
}

function AccessExchangeOnline {
    param (
        [Parameter(Mandatory)]$AdminUsername,
        [Parameter(Mandatory)][PSCredential] $AdminCredential,
        $AccessToken
    )
    ###Connect ExchangeOnline
    if ($AccessToken -notin "",$null ) {
        try {
        #Attempt token authentication  
        Connect-ExchangeOnline -AadAccessToken $AccessToken -AccountId $AdminUsername -ShowBanner:$false -ErrorAction Stop | Out-Null
        Write-Host "[.]Established access to ExchangeOnline`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Token authentication failed. Attempting basic authentication now..."
            try {
                #Attempt basic authentication
                Connect-ExchangeOnline -Credential $AdminCredential -WarningAction SilentlyContinue -ShowBanner:$false -ErrorAction Stop| Out-Null 
                Write-Host "[.]Established access to ExchangeOnline`n" -ForegroundColor Yellow
            }
            catch [Microsoft.Identity.Client.MsalUiRequiredException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                        Write-Host "[.]Established access to ExchangeOnline`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                        Write-Host "[.]Established access to ExchangeOnline`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
            }
            catch {
                Write-Host "Failed to establish access to ExchangeOnline. Validate credentials!`n" -ForegroundColor Red
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-ExchangeOnline -Credential $AdminCredential -WarningAction SilentlyContinue -ShowBanner:$false -ErrorAction Stop | Out-Null 
            Write-Host "[.]Established access to ExchangeOnline`n" -ForegroundColor Yellow  
        }
        catch [Microsoft.Identity.Client.MsalUiRequiredException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                    Write-Host "[.]Established access to ExchangeOnline`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                Write-Host "Invalid credentials!`n" -ForegroundColor Red
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                    Write-Host "[.]Established access to ExchangeOnline`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Failed to establish access to ExchangeOnline. Validate credentials!`n" -ForegroundColor Red
        }
    }
}

function AccessMsol {
    param (
        [Parameter(Mandatory)]$AdminUsername,
        [Parameter(Mandatory)][PSCredential] $AdminCredential,
        $AccessToken
    )
    ###Connect Msol
    if ($AccessToken -notin "",$null) {
        try {
        #Attempt token authentication  
        Connect-MsolService -AdGraphAccessToken $AccessToken -ErrorAction Stop | Out-Null
        Write-Host "[.]Established access to Msol`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Token authentication failed. Attempting basic authentication now..."
            try {
                #Attempt basic authentication
                Connect-MsolService -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                Write-Host "[.]Established access to Msol" -ForegroundColor Yellow
            }
            catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-MsolService -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to Msol`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "Failed to establish access to Msol. Validate credentials!`n" -ForegroundColor Red
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-MsolService -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            Write-Host "[.]Established access to Msol`n" -ForegroundColor Yellow  
        }
        catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-MsolService -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to Msol`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                Write-Host "Invalid credentials!`n" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to establish access to Msol. Validate credentials!`n" -ForegroundColor Red
        }
    }
}

function AccessSharepoint {
    param (
        [Parameter(Mandatory)]$AdminUsername,
        [Parameter(Mandatory)][PSCredential] $AdminCredential,
        $AccessToken
    )
    ###Connect Sharepoint
    Write-Host "Attempting access to SharePoint..." -ForegroundColor Gray
    #$sharepoint_url = Read-Host -Prompt "Enter sharepoint url (or leave blank if you would like the tool to OSINT and find the url"

    #Find the sharepoint URL
    if ($sharepoint_url -notin "No","no","N","n"){
        $tenant = $AdminUsername.Split("@")[1]
        $tenant_intel = Invoke-AADIntReconAsOutsider -DomainName $tenant | Out-Null

        foreach ($domain in $tenant_intel){
            #Write-Host $domain.Name
            if ($domain.Name -match ".onmicrosoft.com" -and $domain.Name -notmatch ".mail.onmicrosoft.com"){
                $global:sharepoint_tenant = $domain.Name.Split(".")[0]
            }
        }
        $sharepoint_url = "https://$global:sharepoint_tenant.sharepoint.com"
        #Write-Host "Sharepoint url: $sharepoint_url"
    }
    
    if ($AccessToken -notin "",$null ) {
        try {
        #Attempt token authentication  
        Connect-PnPOnline -Url $sharepoint_url -AccessToken $AccessToken -ErrorAction Stop | Out-Null
        Write-Host "[.]Established access to SharePoint`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Token authentication failed. Attempting basic authentication now..."
            try {
                #Attempt basic authentication
                Connect-PnPOnline -Url $sharepoint_url -Credentials $AdminCredential -ErrorAction Stop
                Write-Host "[.]Established access to SharePoint`n" -ForegroundColor Yellow
            }
            catch [Microsoft.Identity.Client.MsalUiRequiredException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to SharePoint`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to SharePoint`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
            }
            catch {
                Write-Host "Failed to establish access to SharePoint. Validate credentials!`n" -ForegroundColor Red
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-PnPOnline -Url $sharepoint_url -Credentials $AdminCredential
            Write-Host "[.]Established access to SharePoint`n" -ForegroundColor Yellow
        }
        catch [Microsoft.Identity.Client.MsalUiRequiredException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to SharePoint`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                Write-Host "Invalid credentials!`n" -ForegroundColor Red
            }
            else {
                Write-Error "Failed to access Sharepoint. `n"
                #Accessing sharepoint via powershell requires explicit consent to allow access to sharepoint. Copy paste this URL in your browser and approve the prompt!
                #URL: https://login.microsoftonline.com/$tenant/adminconsent?client_id=$client_id
                Write-Host "Accessing sharepoint via powershell requires explicit consent to allow access to sharepoint."
                $null = Read-Host "MAAD-AF will now launch an authorization page on your browser. Consent to the terms and hit authorize, then return here. press 'Enter' to launch the browser authorization page" 
                Register-PnPManagementShellAccess
                Write-Host "Note: If the browser does not launch automatically for some reason. Open your browser and use this URL to visit the authorization page `nURL: https://login.microsoftonline.com/$tenant/adminconsent?client_id=9bc3ab49-b65d-410a-85ad-de819febfddc `n" -ForegroundColor Gray
                
                $user_prompt = Read-Host "Once you have completed the authorization in browser press 'Enter' to continue or type 'exit' to exit the module..." 
                
                if ($user_prompt.ToLower() -eq "exit") {
                    break
                }
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to SharePoint`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Failed to establish access to SharePoint. Validate credentials!`n" -ForegroundColor Red
        }
    }
}


function AccessSharepointAdmin {
    param (
        [Parameter(Mandatory)]$AdminUsername,
        [Parameter(Mandatory)][PSCredential] $AdminCredential,
        $AccessToken
    )
    ###Connect SharePoint Online Administration Center 
    if ($AccessToken -notin "",$null) {
        try {
        #Attempt token authentication  
        Connect-SPOService -Url "https://$global:sharepoint_tenant-admin.sharepoint.com" -AccessToken $AccessToken -ErrorAction Stop | Out-Null
        #SPOService currently does not support token auth so this is intended to fail and rollover to other auth methods
        Write-Host "[.]Established access to SharePoint Online Administration Center`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Token authentication failed. Attempting basic authentication now..."
            try {
                #Attempt basic authentication
                Connect-SPOService -Url "https://$global:sharepoint_tenant-admin.sharepoint.com" -Credential $AdminCredential -ErrorAction Stop
                Write-Host "[.]Established access to SharePoint Online Administration Center`n" -ForegroundColor Yellow
            }
            catch [Microsoft.Online.SharePoint.PowerShell.AuthenticationException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-SPOService -Url "https://$global:sharepoint_tenant-admin.sharepoint.com" -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to SharePoint Online Administration Center`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "Failed to establish access to SharePoint Online Administration Center. Validate credentials!`n" -ForegroundColor Red
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-SPOService -Url "https://$global:sharepoint_tenant-admin.sharepoint.com" -Credential $AdminCredential -ErrorAction Stop
            Write-Host "[.]Established access to SharePoint Online Administration Center`n" -ForegroundColor Yellow 
        }
        catch [Microsoft.Online.SharePoint.PowerShell.AuthenticationException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-SPOService -Url "https://$global:sharepoint_tenant-admin.sharepoint.com" -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to SharePoint Online Administration Center`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                Write-Host "Invalid credentials!`n" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to establish access to SharePoint Online Administration Center. Validate credentials!`n" -ForegroundColor Red
        }
    }
}