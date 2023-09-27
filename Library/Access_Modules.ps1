function EstablishAccess ($target_service){
    Write-MAADLog "start" "EstablishAccess"

    #Setting all variables as $null
    $global:current_username, $global:current_password, $global:current_access_token, $global:current_credentials = $null
    Write-Host ""

    #Checking if saved credentials are available in credentials.json
    try {
        $credential_file_path = $global:maad_credential_store
        $available_credentials = Get-Content $credential_file_path | ConvertFrom-Json
    }
    catch {
        Write-Host "[CS Error] Failed to access credentials file" -ForegroundColor Red
    }

    if ($null -ne $available_credentials){
        #Display available credentials
        foreach ($credential in $available_credentials.PSObject.Properties){        
            $credential_type = $credential.Value.type
            if ($credential.Value.type -eq "password"){
                Write-Host ($credential_type).ToUpper() "### UID:" $credential.Name "[Username: $($credential.Value.username)]"-ForegroundColor Yellow
            }
            elseif ($credential.Value.type -eq "token"){
                Write-Host ($credential_type).ToUpper() "   ###" $credential.Name -ForegroundColor Yellow
            }
        }

        do{
            $retrived_creds = $false
            $credential_choice = Read-Host -Prompt "`nEnter ID to select credential from store"
            if ($credential_choice -in $null, "") {
                break
            }
            foreach ($credential in $available_credentials.PSObject.Properties){
                if ($credential.Name -eq $credential_choice){
                    if ($credential.Value.type -eq "password"){
                        $global:current_username  = $credential.Value.username
                        $global:current_password = $credential.Value.password
                        $retrived_creds = $true
                        break
                    }
                    elseif ($credential.Value.type -eq "token"){
                        $global:current_access_token = $credential.Value.token
                        $retrived_creds = $true
                        break
                    }
                }
            }
        }while($retrived_creds -eq $false)
    }
    else{
        #Do nothing
    }

    #Get credentials if not found in config file
    if ($global:current_username -in $null,"" -or $global:current_password -in "",$null) {
        Write-Host "`nEnter credentials to access Azure AD & M365 environment" -ForegroundColor Red
        $global:current_username = Read-Host -Prompt "Enter username:"
        $global:current_secure_pass = Read-Host -Prompt "Enter $global:current_username password:" -AsSecureString 
        $global:current_credentials = New-Object System.Management.Automation.PSCredential -ArgumentList ($global:current_username, $global:current_secure_pass)
        Write-Host "`nTip: You can store credentials in MAAD_Credential_Store. Use command: 'ADD CREDS'" -ForegroundColor Gray
    }
    else {
        Write-Host "`nRetrieved credentials..." -ForegroundColor Gray
        $global:current_secure_pass = ConvertTo-SecureString $global:current_password -AsPlainText -Force
        $global:current_credentials = New-Object System.Management.Automation.PSCredential -ArgumentList ($global:current_username, $global:current_secure_pass)
    }
    
    switch ($target_service) {
        "azure_ad"{AccessAzureAD $global:current_username $global:current_credentials $global:current_access_token}
        "az"{AccessAzAccount $global:current_username $global:current_credentials $global:current_access_token}
        "exchange_online"{AccessExchangeOnline $global:current_username $global:current_credentials $global:current_access_token}
        "teams"{AccessTeams $global:current_username $global:current_credentials $global:current_access_token}
        "msol"{AccessMsol $global:current_username $global:current_credentials $global:current_access_token}
        "sharepoint_site"{AccessSharepoint $global:current_username $global:current_credentials $global:current_access_token}
        "sharepoint_admin_center"{AccessSharepointAdmin $global:current_username $global:current_credentials $global:current_access_token}
        "ediscovery"{ConnectEdiscovery $global:current_credentials}
        Default {
            AccessAzureAD $global:current_username $global:current_credentials $global:current_access_token
            AccessAzAccount $global:current_username $global:current_credentials $global:current_access_token
            AccessTeams $global:current_username $global:current_credentials $global:current_access_token
            AccessExchangeOnline $global:current_username $global:current_credentials $global:current_access_token
            AccessMsol $global:current_username $global:current_credentials $global:current_access_token
            AccessSharepoint $global:current_username $global:current_credentials $global:current_access_token
            AccessSharepointAdmin $global:current_username $global:current_credentials $global:current_access_token
            ConnectEdiscovery $global:current_credentials
        
            #Display access info after establishing connection
            AccessInfo
        }
    }
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
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
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
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
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
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                    try {
                        #Attempt interactive authentication  
                        Connect-AzAccount -ErrorAction Stop | Out-Null
                        Write-Host "[.]Established access to Az`n" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "Invalid credentials!`n" -ForegroundColor Red
                    }
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
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                Write-Host "Account requires interactive MFA for authentication.`nLaunching interactive authentication window to continue..." -ForegroundColor Gray
                try {
                    #Attempt interactive authentication  
                    Connect-AzAccount -ErrorAction Stop | Out-Null
                    Write-Host "[.]Established access to Az`n" -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Invalid credentials!`n" -ForegroundColor Red
                }
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
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
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
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
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
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
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
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
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
        $tenant_intel = Invoke-AADIntReconAsOutsider -DomainName $tenant

        foreach ($domain in $tenant_intel){
            #Write-Host $domain.Name
            if ($domain.Name -match ".onmicrosoft.com" -and $domain.Name -notmatch ".mail.onmicrosoft.com"){
                $global:sharepoint_tenant = $domain.Name.Split(".")[0]
            }
        }
        $sharepoint_url = "https://$global:sharepoint_tenant.sharepoint.com"
        Write-Host "Sharepoint url: $sharepoint_url"
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

    #Find the sharepoint URL
    if ($sharepoint_url -notin "No","no","N","n"){
        $tenant = $AdminUsername.Split("@")[1]
        $tenant_intel = Invoke-AADIntReconAsOutsider -DomainName $tenant

        foreach ($domain in $tenant_intel){
            #Write-Host $domain.Name
            if ($domain.Name -match ".onmicrosoft.com" -and $domain.Name -notmatch ".mail.onmicrosoft.com"){
                $global:sharepoint_tenant = $domain.Name.Split(".")[0]
            }
        }
        $sharepoint_url = "https://$global:sharepoint_tenant.sharepoint.com"
        Write-Host "Sharepoint url: $sharepoint_url"
    }

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

function ConnectSharepointSite ($target_site_url, [pscredential]$access_credential) {
    try{
        Write-Host "`nAttempting access to SharePoint site..." -ForegroundColor Gray
        Connect-PnPOnline -Url $target_site_url -Credentials $access_credential
        Write-Host "`n[Success] Connected to SharePoint site: $target_site_url" -ForegroundColor Yellow
    }
    catch [System.Exception]{
        if ($null -ne ($_.Exception.Message | Select-String -Pattern "Forbidden")){
            Write-Host "`n[Error] I guess you can't get everything!`nThis account DOES NOT have access to this SharePoint site. Try another site from the list or attempt to gain access to this site." -ForegroundColor Red
            return
        }
        else {
            Write-Host $_
            return
        }
    }
    catch{
        Write-Host "`n[Error] Unable to access sharepoint site" -ForegroundColor Red
    }
}

function ConnectEdiscovery ([pscredential]$access_credential){
    Write-Host "Establishing access to Security & Compliance portal..." -ForegroundColor Gray

    try {
        Connect-IPPSSession -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $access_credential
        Start-Sleep -Seconds 5
        Write-Host "`n[.] Established access to Security & Compliance" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`nFailed to establish session with compliance portal with the current credentials!" -ForegroundColor Red
    }
}

function terminate_connection {

    Write-Host "`nClosing all active connections........." -ForegroundColor Gray
    try {
        Disconnect-AzureAD -Confirm:$false | Out-Null
    }
    catch {
        #do nothing
    }

    try {
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    }
    catch {
        #do nothing
    }
    try {
        Disconnect-AzAccount -Confirm:$false | Out-Null
    }
    catch {
        #do nothing
    }
    try {
        Disconnect-MicrosoftTeams -Confirm:$false | Out-Null
    }
    catch {
        #do nothing
    }
    try {
        Disconnect-PnPOnline | Out-Null
    }
    catch {
        #do nothing
    }
    try {
        Disconnect-SPOService | Out-Null
    }
    catch {
        #do nothing
    }
    try {
        [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState() | Out-Null
    }
    catch {
        #do nothing
    }
    try {
        if($null -ne (Get-MgContext)){
            Disconnect-MgGraph | Out-Null
        }
    }
    catch {
        #do nothing
    }
    Write-MAADLog "info" "connections terminated"
}