#Credential Store Manager
function RetrieveCredentials{
    $credential_file_path = $global:maad_credential_store

    #Function to retrieve credentials in MAAD
    try {
        $available_credentials = Get-Content $credential_file_path | ConvertFrom-Json
    }
    catch {
        Write-Host "`n[CS Error] Failed to access credentials file" -ForegroundColor Red
        break
    }

    #Check if credential store is empty
    if ($null -eq $available_credentials) {
        Write-Host "`n[CS Info] Credential store is empty!" -ForegroundColor Red
        Write-Host "`n[Hint] Use 'ADD CREDS' to add new credentials" -ForegroundColor DarkGray
    }
    else {
    
        Write-Host "`nListing credentials in MAAD-AF credential store...`n" -ForegroundColor Gray

        foreach ($cred in $available_credentials.PSObject.Properties){
            #$cred | Format-Table
            $available_credentials.($cred.Name) | Format-Table
        }
    }
}

function AddCredentials ($new_cred_type, $name, $new_username, $new_password, $new_token){
    $credential_file_path = $global:maad_credential_store

    #Load latest stored credentials to global:all_credentials
    try {
        $all_credentials = Get-Content $credential_file_path | ConvertFrom-Json
    }
    catch {
        Write-Host "`n[CS Error] Failed to access credentials file" -ForegroundColor Red
        break
    }
    
    if ($null -ne $all_credentials){
        if ($new_cred_type -eq "password"){
            $all_credentials | Add-Member -MemberType NoteProperty -Name $name -Value ([PSCustomObject]@{
                type = $new_cred_type
                username = $new_username
                password = $new_password
            })
        }
        elseif ($new_cred_type -eq "token"){
            $all_credentials | Add-Member -MemberType NoteProperty -Name $name -Value ([PSCustomObject]@{
                type = $new_cred_type
                token = $new_token
            })
        }
        elseif ($new_cred_type -eq "application"){
            $all_credentials | Add-Member -MemberType NoteProperty -Name $name -Value ([PSCustomObject]@{
                type = $new_cred_type
                application = $new_username
                password = $new_password
            })
        }
        else{
            Write-Host "`nNot a valid credential type" -ForegroundColor Red
            break
        }
    }

    elseif ($null -eq $all_credentials){
        if ($new_cred_type -eq "password"){
            $all_credentials = ([PSCustomObject]@{
                $name = @{
                    type = $new_cred_type
                    username = $new_username
                    password = $new_password
                }     
            })
        }
        elseif ($new_cred_type -eq "token"){
            $all_credentials = ([PSCustomObject]@{
                $name = @{
                    type = $new_cred_type
                    token = $new_token
                }     
            })
        }
        elseif ($new_cred_type -eq "application"){
            $all_credentials = ([PSCustomObject]@{
                $name = @{
                    type = $new_cred_type
                    username = $new_username
                    password = $new_password
                }     
            })
        }
        else{
            Write-Host "`n[Input Error] Not a valid credential type" -ForegroundColor Red
            break
        }
    }

    #Save new creds to file
    try {
        $all_credentials_json = $all_credentials | ConvertTo-Json
        $all_credentials_json | Set-Content -Path $credential_file_path -Force
        Write-Host "`n[CS Updated] New credentials added to MAAD-AF credentials store" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`n[CS Error] Failed to store credentials to MAAD-AF credential store" -ForegroundColor Red
    }
}

function UseCredential {
    ###This function sets the global variables global:current_username + global:current_password or global:current_access_token to use with modules that require instataneous login

    #Checking if saved credentials are available in credentials.json
    try {
        $credential_file_path = $global:maad_credential_store
        $available_credentials = Get-Content $credential_file_path | ConvertFrom-Json
    }
    catch {
        Write-Host "Failed to access credentials file" -ForegroundColor Red
    }

    if ($null -ne $available_credentials){
        #Display available credentials
        foreach ($credential in $available_credentials.PSObject.Properties){        
            $credential_type = $credential.Value.type
            if ($credential.Value.type -eq "password"){
                Write-Host ($credential_type).ToUpper() "### CID:" $credential.Name "[Username: $($credential.Value.username)]"
            }
            elseif ($credential.Value.type -eq "token"){
                Write-Host ($credential_type).ToUpper() "   ### CID:" $credential.Name
            }
        }

        do{
            $retrived_creds = $false
            $credential_choice = Read-Host -Prompt "`nEnter CID to select credential from store"
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
}