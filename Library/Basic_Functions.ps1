###Basic functions
function RequiredModules {
    ###This function checks for required modules by MAAD and Installs them if unavailable
    $RequiredModules=@("Az","AzureAd","MSOnline","ExchangeOnlineManagement","MicrosoftTeams","AzureADPreview","AADInternals","Microsoft.Online.SharePoint.PowerShell","PnP.PowerShell","Microsoft.Graph.Identity.SignIns")
    Write-Host "`nMAAD-AF requires the following powershell modules:`n$RequiredModules" -ForegroundColor Gray
    $allow = Read-Host -Prompt "`nAutomatically check for dependencies and install missing modules? (Yes / No)"

    if ($allow -notin "No","no","N","n") {
        Write-Host "Checking all required modules..." -ForegroundColor Gray

        foreach ($module in $RequiredModules.GetEnumerator()) {
            if (Get-InstalledModule -Name $($module) ) {
                try {
                    Import-Module -Name $($module) -WarningAction SilentlyContinue
                }
                catch {
                    Write-Host "Failed to import. Skippig module: $module. " -ForegroundColor Red
                }  
            } 
            else {
                Write-Host "'$module' module does NOT exist. The tool will attempt to install it now..." -ForegroundColor Gray
                try {
                    Set-ExecutionPolicy Unrestricted -Force
                    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
                    Install-Module -Name $($module) -Confirm:$False -WarningAction SilentlyContinue
                    Import-Module -Name $($module) -WarningAction SilentlyContinue
                }
                catch {
                    Write-Host "Failed to install. Skippig module: $module. " -ForegroundColor Red
                }   
            }
        }
        Write-Host "All required modules available!" -ForegroundColor Gray
    }
    else {
        Write-Host "Note: Some functions may fail if required modules are missing" -ForegroundColor Gray
    }  
    #To prevent overwrite from any imported modules 
    $host.UI.RawUI.WindowTitle = "MAAD Attack Framework"
} 

function ClearActiveSessions {
    Get-PSSession | Remove-PSSession
}

function terminate_connection {
    try {
        Write-Host "`nClosing all existing connections........." -ForegroundColor Yellow -BackgroundColor Black
        Disconnect-AzureAD -Confirm:$false | Out-Null
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
        Disconnect-AzAccount -Confirm:$false | Out-Null
        Disconnect-MicrosoftTeams -Confirm:$false | Out-Null
        Disconnect-PnPOnline | Out-Null
        Disconnect-SPOService | Out-Null
        [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState() | Out-Null
    }
    catch {
        #Do nothing. We are leaving. Bye!
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

function EnterMailbox ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options.If valid, returns mailbox address($global:input_mailbox_address)
    $repeat = $false
    do {
        $global:input_mailbox_address = Read-Host -Prompt $input_prompt

        if ($global:input_mailbox_address.ToUpper() -eq "RECON" -or $global:input_mailbox_address -eq "" -or $global:input_mailbox_address -eq $null) {
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
            ValidateMailbox($global:input_mailbox_address)
            if ($global:mailbox_found -eq $true) {
                $repeat = $false
            }
            if ($global:mailbox_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true) 
}

function ValidateMailbox ($mailbox_address){
    ###This function returns if a mailbox address is valid ($mailbox_found = $true) or not ($mailbox_found = $false)
    $global:mailbox_found = $false
    try {
        Get-Mailbox -Identity $mailbox_address -ErrorAction Stop
        Write-Host ""
        $global:mailbox_found = $true
    }
    catch {
        Write-Host "`nThe mailbox does not exist or the account does not have a mailbox setup.`n" -ForegroundColor Red
        $global:mailbox_found = $false
    }
}

function EnterAccount ($input_prompt){
    ###This function takes user input and checks for its validity. If invalid, then executes recon to show available options. If valid, returns account name($global:input_user_account)
    $repeat = $false
    do {
        $global:input_user_account = Read-Host -Prompt $input_prompt

        if ($global:input_user_account.ToUpper() -eq "RECON" -or $global:input_user_account -eq "" -or $global:input_user_account -eq $null) {
            try {
                Write-Host "`nExecuting recon to list available accounts in the tenant" -ForegroundColor Gray
                Get-AzureADUser | Format-Table -Property DisplayName,UserPrincipalName,UserType
                $repeat = $true
            }
            catch {
                Write-Host "Failed to find mailboxes" -ForegroundColor Red
                $repeat = $false
            }
        }
        else {
            ValidateAccount($global:input_user_account)
            if ($global:account_found -eq $true) {
                $repeat = $false
            }
            if ($global:account_found -eq $false){
                $repeat = $true
            }
        }  
    } while ($repeat -eq $true)  
}

function ValidateAccount ($account_username){
    ###This function returns if an account exists in Azure AD ($account_found = $true) or not ($account_found = $false)
    $global:account_found = $false

    $check_account = Get-AzureADUser -SearchString $account_username
    
    if ($check_account -eq $null){
        Write-Host "The account does not exist or match an account in the tenant!`n" -ForegroundColor Red
        $global:account_found = $false
    }
    
    else {
        if ($check_account.GetType().BaseType.Name -eq "Array"){
            Write-Host "Multiple accounts found matching your search. Lets take things slow ;) Be more specific to target one account!" -ForegroundColor Red
            $global:account_found = $false
        }
        else {
            Write-Host "Account found!!!"
            $account_username = $check_account.UserPrincipalName
            $global:account_found = $true
        }
    }
}