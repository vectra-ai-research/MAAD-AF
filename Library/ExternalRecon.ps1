function MAADReconTenantID {
    param (
        $target_input
    )

    if ($null -eq $target_input){
        $target_input = Read-Host -Prompt "`nEnter tenant domain or an email address"
    }

    if ($target_input.Contains("@")) {
        $target_input = $target_input.Split("@")[1]
    }

    try {
        $tenant_info = Invoke-WebRequest -Method Get -Uri "login.microsoftonline.com/$target_input/.well-known/openid-configuration" | ConvertFrom-Json
        $token_endpoint = $tenant_info.token_endpoint
        $tenant_id = [regex]::Match($token_endpoint, "[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}").Value

        Write-Host "`n[Success] Tenant ID found: $tenant_id" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`n[Error] Failed to find tenant ID" -ForegroundColor Red
    }
    Pause
}

function MAADReconDNSInfo {
    param (
        $target_input
    )

    if ($null -eq $target_input){
        $target_input = Read-Host -Prompt "`nEnter tenant domain or an email address"
    }
    
    if ($target_input.Contains("@")) {
        $target_tenant_domain = $target_input.Split("@")[1]
    }

    $type_options = @{1 = "A"; 2 = "AAAA"; 3 = "TXT"; 4 = "MX"; 5 = "CNAME"}
    OptionDisplay "Select a record type:" $type_options

    $type = Read-Host -Prompt "Select a record type"
    $selected_type = $type_options.[int]$type

    if ($selected_type -in $type_options.Values){
        Write-Host "`n[.] Retrieving DNS info for domain: $target_tenant_domain ..." -ForegroundColor Gray
        Resolve-DnsName -Name $target_tenant_domain -Type $selected_type | Format-Table
    }
    Pause
}

function MAADUserLoginInfo {
    <#
    This module is based on the amazing research by @DrAzureAD
    Ref: https://aadinternals.com/post/just-looking/
    #>
    param (
        $target_input
    )

    if ($null -eq $target_input){
        $target_input = Read-Host -Prompt "`nEnter a username to target (user@domain.com)"
    }

    Write-Host "`n[.] Retrieving tenant login info..." -ForegroundColor Gray

    $user_login_info = Invoke-WebRequest -Method Get -Uri "login.microsoftonline.com/GetUserRealm.srf?login=$target_input" | ConvertFrom-Json

    $user__login_info_2 = Invoke-RestMethod -Uri "https://login.microsoftonline.com/common/GetCredentialType" -ContentType "application/json" -Method POST -Body $body | Select Display, IfExistsResult, IsUnmanaged, Credentials

    $user_login_info
    $user__login_info_2
    Pause
}

function MAADCheckUserValidity {
    <#
    This module is based on the amazing research by @DrAzureAD
    Ref: https://aadinternals.com/post/desktopsso/
    #>
    param (
        $target_input
    )

    if ($null -eq $target_input){
        $target_input = Read-Host -Prompt "`nEnter a username to check if it exists"
    }

    $body = @{
        "username"="$target_input"; 
        "isOtherIdpSupported" =  $true
    } | ConvertTo-Json

    $user_validity = Invoke-RestMethod -Uri "https://login.microsoftonline.com/common/GetCredentialType" -ContentType "application/json" -Method POST -Body $body

    if ($user_validity.IfExistsResult -eq 0){
        $result = [ordered]@{"Username" =  $target_input; "Valid" = $true}
        Write-Host ""
        New-Object -TypeName PSObject -Property $result
    }
    else{
        $result = [ordered]@{"Username" =  $target_input; "Valid" = $false}
        Write-Host ""
        New-Object -TypeName PSObject -Property $result
    }
    Pause
}

function MAADEnumerateValidUsers {
    Write-Host "`n[Note] Place the file in ./MAAD-AF/Local" -ForegroundColor Gray
    $input_file = Read-Host "`nEnter users list file name (eg: users.txt)"

    $filename = $input_file.Trim()
    $check_file = Test-Path -Path .\Local\$filename
    
    if ($check_file -and $filename -ne "") {
        Write-Host "`n[.] File found" -ForegroundColor Gray
        #Check file format - Only txt files accepted
        $extn = [IO.Path]::GetExtension($filename) 
        if ($extn -ne ".txt") {
            Write-Host "`n[Error] Invalid file type: Please provide a 'txt' dictionary file with one username per line." -ForegroundColor Red
            $check_file = $false
        }
        else {
            $check_file = $true
        } 
    }
    else {
        Write-Host "`n[Error] File: '$filename' not found" -ForegroundColor Red
        Write-Host "`nCheck : `n1.If the spelling is correct `n2.If the file exists in the ./MAAD-AF/Local directory `n3.Include file extension in input" -ForegroundColor Gray
        $check_file = $false
    }

    if ($check_file){
        $users = Get-Content -Path .\Local\$filename
        Write-Host "`n[.] Starting user enumeration to find valid users ..." -ForegroundColor Gray

        foreach ($user in $users) {
            MAADCheckUserValidity $user
        }
    }
    Pause
}