function EstablishAccess ($target_service){
    Write-MAADLog "start" "EstablishAccess"

    UseCredential
    
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
            MAADPause
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
        MAADWriteSuccess "Established access -> AzureAD"
        }
        catch {
            MAADWriteError "Token authentication failed"
            MAADWriteProcess "Attempting basic authentication"
            try {
                #Attempt basic authentication
                Connect-AzureAD -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                MAADWriteSuccess "Established access -> AzureAD"
            }
            catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-AzureAD -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> AzureAD"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    MAADWriteError "Invalid credentials"
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    MAADWriteInfo "Account requires interactive MFA for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-AzureAD -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> AzureAD"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
            }
            catch {
                MAADWriteError "Failed to establish access -> AzureAD"
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-AzureAD -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            MAADWriteSuccess "Established access -> AzureAD"  
        }
        catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-AzureAD -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> AzureAD"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                MAADWriteError "Invalid credentials"
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-AzureAD -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> AzureAD"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
        }
        catch {
            MAADWriteError "Failed to establish access -> AzureAD"
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
        MAADWriteSuccess "Established access -> Az"
        }
        catch {
            MAADWriteError "Token authentication failed"
            MAADWriteProcess "Attempting basic authentication"
            try {
                #Attempt basic authentication
                Connect-AzAccount -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                MAADWriteSuccess "Established access -> Az"
            }
            catch [Microsoft.Azure.Commands.Common.Exceptions.AzPSAuthenticationFailedException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-AzAccount -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> Az"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    MAADWriteError "Invalid credentials"
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-AzAccount -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> Az"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
            }
            catch {
                MAADWriteError "Failed to establish access -> Az"
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-AzAccount -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            MAADWriteSuccess "Established access -> Az"
        }
        catch [Microsoft.Azure.Commands.Common.Exceptions.AzPSAuthenticationFailedException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-AzAccount -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> Az"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                MAADWriteError "Invalid credentials"
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-AzAccount -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> Az"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
        }
        catch {
            $_
            MAADWriteError "Failed to establish access -> Az"
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
        MAADWriteSuccess "Established access -> Teams"
        }
        catch {
            MAADWriteError "Token authentication failed"
            MAADWriteProcess "Attempting basic authentication"
            try {
                #Attempt basic authentication
                Connect-MicrosoftTeams -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                MAADWriteSuccess "Established access -> Teams"
            }
            catch [System.AggregateException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> Teams"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    MAADWriteError "Invalid credentials"
                    $null = Read-Host "Exiting"
                    exit
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> Teams"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
            }
            catch {
                MAADWriteError "Failed to establish access -> Teams"
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-MicrosoftTeams -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            MAADWriteSuccess "Established access -> Teams"  
        }
        catch [System.AggregateException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> Teams"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                MAADWriteError "Invalid credentials"
                $null = Read-Host "Exiting"
                exit
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-MicrosoftTeams -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> Teams"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
        }
        catch {
            MAADWriteError "Failed to establish access -> Teams"
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
        MAADWriteSuccess "Established access -> ExchangeOnline"
        }
        catch {
            MAADWriteError "Token authentication failed"
            MAADWriteProcess "Attempting basic authentication"
            try {
                #Attempt basic authentication
                Connect-ExchangeOnline -Credential $AdminCredential -WarningAction SilentlyContinue -ShowBanner:$false -ErrorAction Stop| Out-Null 
                MAADWriteSuccess "Established access -> ExchangeOnline"
            }
            catch [Microsoft.Identity.Client.MsalUiRequiredException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                        MAADWriteSuccess "Established access -> ExchangeOnline"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    MAADWriteError "Invalid credentials"
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                        MAADWriteSuccess "Established access -> ExchangeOnline"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
            }
            catch {
                MAADWriteError "Failed to establish access -> ExchangeOnline"
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-ExchangeOnline -Credential $AdminCredential -WarningAction SilentlyContinue -ShowBanner:$false -ErrorAction Stop | Out-Null 
            MAADWriteSuccess "Established access -> ExchangeOnline"  
        }
        catch [Microsoft.Identity.Client.MsalUiRequiredException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                    MAADWriteSuccess "Established access -> ExchangeOnline"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                MAADWriteError "Invalid credentials"
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-ExchangeOnline -ErrorAction Stop -ShowBanner:$false | Out-Null
                    MAADWriteSuccess "Established access -> ExchangeOnline"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
        }
        catch {
            MAADWriteError "Failed to establish access -> ExchangeOnline"
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
        MAADWriteSuccess "Established access -> Msol"
        }
        catch {
            MAADWriteError "Token authentication failed"
            MAADWriteProcess "Attempting basic authentication"
            try {
                #Attempt basic authentication
                Connect-MsolService -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
                MAADWriteSuccess "Established access -> Msol"
            }
            catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-MsolService -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> Msol"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    MAADWriteError "Invalid credentials"
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-MsolService -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> Msol"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
            }
            catch {
                MAADWriteError "Failed to establish access -> Msol"
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-MsolService -Credential $AdminCredential -WarningAction SilentlyContinue -ErrorAction Stop| Out-Null 
            MAADWriteSuccess "Established access -> Msol"  
        }
        catch [Microsoft.Open.Azure.AD.CommonLibrary.AadAuthenticationFailedException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-MsolService -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> Msol"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                MAADWriteError "Invalid credentials"
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-MsolService -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> Msol"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
        }
        catch {
            MAADWriteError "Failed to establish access -> Msol"
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
    MAADWriteProcess "Attempting access to SharePoint"

    #Find the sharepoint URL
    if ($sharepoint_url -notin "No","no","N","n"){
        $tenant = $AdminUsername.Split("@")[1]
        $tenant_intel = Invoke-AADIntReconAsOutsider -DomainName $tenant

        foreach ($domain in $tenant_intel){
            if ($domain.Name -match ".onmicrosoft.com" -and $domain.Name -notmatch ".mail.onmicrosoft.com"){
                $global:sharepoint_tenant = $domain.Name.Split(".")[0]
            }
        }
        $sharepoint_url = "https://$global:sharepoint_tenant.sharepoint.com"
        MAADWriteProcess "SharePoint url -> $sharepoint_url"
    }
    
    if ($AccessToken -notin "",$null ) {
        #Set environment variable to disable PNP module version check 
        $env:PNPPOWERSHELL_UPDATECHECK= $false
        
        try {
        #Attempt token authentication  
        Connect-PnPOnline -Url $sharepoint_url -AccessToken $AccessToken -ErrorAction Stop | Out-Null
        MAADWriteSuccess "Established access -> SharePoint"
        }
        catch {
            MAADWriteError "Token authentication failed"
            MAADWriteProcess "Attempting basic authentication"
            try {
                #Attempt basic authentication
                Connect-PnPOnline -Url $sharepoint_url -Credentials $AdminCredential -ErrorAction Stop
                MAADWriteSuccess "Established access -> SharePoint"
            }
            catch [Microsoft.Identity.Client.MsalUiRequiredException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> SharePoint"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    MAADWriteError "Invalid credentials"
                }
            }
            catch [System.Exception]{
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> SharePoint"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
            }
            catch {
                MAADWriteError "Failed to establish access -> SharePoint"
            }
        }
    }
    else {
        #Set environment variable to disable PNP module version check 
        $env:PNPPOWERSHELL_UPDATECHECK= $false

        try {
            #Attempt basic authentication
            Connect-PnPOnline -Url $sharepoint_url -Credentials $AdminCredential -ErrorAction Stop
            MAADWriteSuccess "Established access -> SharePoint"
        }
        catch [Microsoft.Identity.Client.MsalUiRequiredException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> SharePoint"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                MAADWriteError "Invalid credentials"
            }
            else {
                MAADWriteError "Failed to access SharePoint"
                #Accessing sharepoint via powershell requires explicit consent to allow access to sharepoint. Copy paste this URL in your browser and approve the prompt!
                #URL: https://login.microsoftonline.com/$tenant/adminconsent?client_id=$client_id
                MAADWriteProcess "Accessing SharePoint via powershell requires explicit consent to allow access to SharePoint"
                MAADWriteInfo "Launching authorization page in browser"
                MAADWriteInfo "Consent to the terms and choose authorize, then return here"
                $null = Read-Host "`n[?] Press [enter] to launch the browser authorization page" 
                Register-PnPManagementShellAccess
                MAADWriteInfo "If the browser does not launch automatically. Visit authorization page : https://login.microsoftonline.com/$tenant/adminconsent?client_id=9bc3ab49-b65d-410a-85ad-de819febfddc"
                
                $user_prompt = Read-Host "`n[?] Once you have completed the authorization in browser press [enter] to continue or type [exit] to quit the module" 
                
                if ($user_prompt.ToLower() -eq "exit") {
                    break
                }
            }
        }
        catch [System.Exception]{
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.InnerException) -or $null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-PnPOnline -Url $sharepoint_url -Interactive -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> SharePoint"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
        }
        catch {
            MAADWriteError "Failed to establish access -> SharePoint"
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
            if ($domain.Name -match ".onmicrosoft.com" -and $domain.Name -notmatch ".mail.onmicrosoft.com"){
                $global:sharepoint_tenant = $domain.Name.Split(".")[0]
            }
        }
        $sharepoint_url = "https://$global:sharepoint_tenant.sharepoint.com"
        MAADWriteProcess "SharePoint url -> $sharepoint_url"
        $sharepoint_admin_url = "https://$global:sharepoint_tenant-admin.sharepoint.com"
        MAADWriteProcess "SharePoint admin url -> $sharepoint_admin_url"
    }

    ###Connect SharePoint Online Administration Center 
    if ($AccessToken -notin "",$null) {
        try {
        #Attempt token authentication  
        Connect-SPOService -Url $sharepoint_admin_url -AccessToken $AccessToken -ErrorAction Stop | Out-Null
        #SPOService currently does not support token auth so this is intended to fail and rollover to other auth methods
        MAADWriteSuccess "Established access -> SharePoint Online Administration Center"
        }
        catch {
            MAADWriteError "Token authentication failed"
            MAADWriteProcess "Attempting basic authentication"
            try {
                #Attempt basic authentication
                Connect-SPOService -Url $sharepoint_admin_url -Credential $AdminCredential -ErrorAction Stop
                MAADWriteSuccess "Established access -> SharePoint Online Administration Center"
            }
            catch [Microsoft.Online.SharePoint.PowerShell.AuthenticationException]{
                #Check if account has MFA requirements for authentication
                if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                    MAADWriteInfo "MFA required for authentication"
                    MAADWriteProcess "Launching interactive authentication window to continue"
                    try {
                        #Attempt interactive authentication  
                        Connect-SPOService -Url $sharepoint_admin_url -ErrorAction Stop | Out-Null
                        MAADWriteSuccess "Established access -> SharePoint Online Administration Center"
                    }
                    catch {
                        MAADWriteError "Invalid credentials"
                    }
                }
                if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                    MAADWriteError "Invalid credentials"
                }
            }
            catch {
                MAADWriteError "Failed to establish access -> SharePoint Online Administration Center"
            }
        }
    }
    else {
        try {
            #Attempt basic authentication
            Connect-SPOService -Url $sharepoint_admin_url -Credential $AdminCredential -ErrorAction Stop
            MAADWriteSuccess "Established access -> SharePoint Online Administration Center" 
        }
        catch [Microsoft.Online.SharePoint.PowerShell.AuthenticationException]{
            #Check if account has MFA requirements for authentication
            if ($null -ne (Select-String -Pattern "multi-factor authentication" -InputObject $_.Exception.Message)) {
                MAADWriteInfo "MFA required for authentication"
                MAADWriteProcess "Launching interactive authentication window to continue"
                try {
                    #Attempt interactive authentication  
                    Connect-SPOService -Url $sharepoint_admin_url -ErrorAction Stop | Out-Null
                    MAADWriteSuccess "Established access -> SharePoint Online Administration Center"
                }
                catch {
                    MAADWriteError "Invalid credentials"
                }
            }
            if ($null -ne (Select-String -Pattern "invalid username or password" -InputObject $_.Exception.Message)) {
                MAADWriteError "Invalid credentials"
            }
        }
        catch {
            MAADWriteError "Failed to establish access -> SharePoint Online Administration Center"
        }
    }
}

function ConnectSharepointSite ($target_site_url, [pscredential]$access_credential) {
    $global:sp_site_connected = $null
    try{
        MAADWriteProcess "Attempting access to SharePoint site"
        Connect-PnPOnline -Url $target_site_url -Credentials $access_credential
        MAADWriteSuccess "Connected to SharePoint site -> $target_site_url"
        $global:sp_site_connected = $true
    }
    catch [System.Exception]{
        if ($null -ne ($_.Exception.Message | Select-String -Pattern "Forbidden")){
            MAADWriteError "Can't get everything ;)"
            MAADWriteError "Account DOES NOT have access to SharePoint site"
            
            $global:sp_site_connected = $false
            return
        }
        else {
            Write-Host $_
            $global:sp_site_connected = $false
            return
        }
    }
    catch{
        MAADWriteError "Unable to access SharePoint site"
    }
}

function ConnectEdiscovery ([pscredential]$access_credential){
    MAADWriteProcess "Attempting access to Compliance portal"

    try {
        Connect-IPPSSession -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid -Credential $access_credential
        Start-Sleep -Seconds 5
        MAADWriteSuccess "Established access -> Compliance portal"
    }
    catch {
        MAADWriteError "Failed to establish access -> Compliance portal"
    }
}

function terminate_connection {

    MAADWriteProcess "Closing all active connections"
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