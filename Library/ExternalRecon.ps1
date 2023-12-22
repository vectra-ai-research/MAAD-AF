function MAADReconTenantID {
    param (
        $target_input
    )

    if ($null -eq $target_input){
        $target_input = Read-Host -Prompt "`n[?] Enter tenant domain or email address"
        Write-Host ""
    }

    if ($target_input.Contains("@")) {
        $target_input = $target_input.Split("@")[1]
    }

    try {
        $tenant_info = Invoke-WebRequest -Method Get -Uri "login.microsoftonline.com/$target_input/.well-known/openid-configuration" | ConvertFrom-Json
        $token_endpoint = $tenant_info.token_endpoint
        $tenant_id = [regex]::Match($token_endpoint, "[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}").Value

        MAADWriteProcess "Tenant ID of $target_input -> $tenant_id"
        MAADWriteSuccess "Tenant ID found"
    }
    catch {
        MAADWriteError "Failed to find tenant ID"
    }
    MAADPause
}

function MAADReconDNSInfo {
    param (
        $target_input
    )

    if ($null -eq $target_input){
        $target_input = Read-Host -Prompt "`n[?] Enter tenant domain or email address"
    }
    
    if ($target_input.Contains("@")) {
        $target_input = $target_input.Split("@")[1]
    }

    $type_options = @{1 = "A"; 2 = "AAAA"; 3 = "TXT"; 4 = "MX"; 5 = "CNAME"}
    OptionDisplay "Select a record type:" $type_options

    $type = Read-Host -Prompt "`n[?] Select a record type"
    Write-Host ""
    $selected_type = $type_options.[int]$type

    if ($selected_type -in $type_options.Values){
        MAADWriteProcess "Fetching DNS info for domain -> $target_input"
        Resolve-DnsName -Name $target_input -Type $selected_type | Format-Table
    }
    MAADPause
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
        $target_input = Read-Host -Prompt "`n[?] Enter target username (user@domain.com)"
        Write-Host ""
    }

    $body = @{
        "username"="$target_input"; 
        "isOtherIdpSupported" =  $true
    } | ConvertTo-Json

    MAADWriteProcess "Running recon to find user login info"

    $user_login_info = Invoke-WebRequest -Method Get -Uri "login.microsoftonline.com/GetUserRealm.srf?login=$target_input" | ConvertFrom-Json

    $user__login_info_2 = Invoke-RestMethod -Uri "https://login.microsoftonline.com/common/GetCredentialType" -ContentType "application/json" -Method POST -Body $body | Select Display, IfExistsResult, IsUnmanaged, Credentials

    MAADWriteProcess "User Login -> $($user_login_info.Login)"
    MAADWriteProcess "Organization -> $($user_login_info.FederationBrandName)"
    MAADWriteProcess "Name Space Type -> $($user_login_info.NameSpaceType)"
    MAADWriteProcess "User Exists -> $($user__login_info_2.IfExistsResult)"
    MAADWriteProcess "Is Unmanaged -> $($user__login_info_2.IsUnmanaged)"
    MAADWriteProcess "Has Password -> $($user__login_info_2.Credentials.HasPassword)"

    MAADPause
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
        $target_input = Read-Host -Prompt "`n[?] Enter a username to check if it exists"
        Write-Host ""
    }

    $body = @{
        "username"="$target_input"; 
        "isOtherIdpSupported" =  $true
    } | ConvertTo-Json

    $user_validity = Invoke-RestMethod -Uri "https://login.microsoftonline.com/common/GetCredentialType" -ContentType "application/json" -Method POST -Body $body

    if ($user_validity.IfExistsResult -eq 0){
        $result = [ordered]@{"Username" =  $target_input; "Valid" = $true}
        # New-Object -TypeName PSObject -Property $result
        MAADWriteProcess "$target_input -> Exists"
    }
    else{
        $result = [ordered]@{"Username" =  $target_input; "Valid" = $false}
        # New-Object -TypeName PSObject -Property $result
        MAADWriteProcess "$target_input -> Does not Exist"
    }
    MAADPause
}

function MAADEnumerateValidUsers {
    MAADWriteInfo "Place the file in ./MAAD-AF/Local"
    $input_file = Read-Host "`n[?] Enter users list file name (eg: users.txt)"
    Write-Host ""

    $filename = $input_file.Trim()
    $check_file = Test-Path -Path .\Local\$filename
    
    if ($check_file -and $filename -ne "") {
        MAADWriteProcess "File found"
        #Check file format - Only txt files accepted
        $extn = [IO.Path]::GetExtension($filename) 
        if ($extn -ne ".txt") {
            MAADWriteError "Invalid file type -> Provide 'txt' file with one username per line"
            $check_file = $false
        }
        else {
            $check_file = $true
        } 
    }
    else {
        MAADWriteError "File not found -> $filename"
        MAADWriteInfo "Check -> If spelling is correct"
        MAADWriteInfo "Check -> If file exists in directory ./MAAD-AF/Local"
        MAADWriteInfo "Include file extension in input"
        $check_file = $false
    }

    if ($check_file){
        $users = Get-Content -Path .\Local\$filename
        MAADWriteProcess "Starting enumeration to find valid users"

        foreach ($user in $users) {
            MAADCheckUserValidity $user
        }
    }
    MAADPause
}