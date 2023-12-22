#Credential Store Manager
function RetrieveCredentials{
    $credential_file_path = $global:maad_credential_store

    #Function to retrieve credentials in MAAD
    try {
        $available_credentials = Get-Content $credential_file_path | ConvertFrom-Json
    }
    catch {
        MAADWriteError "MCS -> Can't Access Credential Store"
        break
    }

    #Check if credential store is empty
    if ($null -eq $available_credentials) {
        MAADWriteError "MCS -> No Credentials Found"
        MAADWriteInfo "MCS -> Use 'ADD CREDS' to Save Credentials"
    }
    else {
        MAADWriteProcess "MCS -> Listing Credentials"

        $all_credentials = $available_credentials.PSObject.Properties

        #Display as table
        $all_credentials | Format-Table -Property @{Label="CID";Expression={$_.Name}}, @{Label="Cred Type";Expression={$_.Value.type}}, @{Label="Username";Expression={$_.Value.username}} -Wrap
    }

    MAADPause
}

function AddCredentials ($new_cred_type, $name, $new_username, $new_password, $new_token){

    #Sanitize user input - trim any leading & trailing spaces
    $new_cred_type = $new_cred_type.Trim()
    $name = $name.Trim()
    $new_username = $new_username.Trim()
    $new_password = $new_password.Trim()

    $credential_file_path = $global:maad_credential_store

    #Load latest stored credentials to global:all_credentials
    try {
        $all_credentials = Get-Content $credential_file_path | ConvertFrom-Json
    }
    catch {
        MAADWriteError "MCS -> Can't Access Credential Store"
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
            MAADWriteError "MCS -> Invalid Credential Type"
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
            MAADWriteError "MCS -> Invalid Credential Type"
            break
        }
    }

    #Save new creds to file
    try {
        $all_credentials_json = $all_credentials | ConvertTo-Json
        $all_credentials_json | Set-Content -Path $credential_file_path -Force
        MAADWriteProcess "MCS -> Credential Stored in MAAD Credential Store"
    }
    catch {
        MAADWriteError "MCS -> Failed to Add Credentials"
    }
}

function UseCredential {
    ###This function sets the global variables global:current_username + global:current_password or global:current_access_token to use with modules that require creds for authentication

    #Setting all variables as $null
    $global:current_username, $global:current_password, $global:current_access_token, $global:current_credentials = $null
    Write-Host ""

    #Checking if saved credentials are available in credentials.json
    try {
        $credential_file_path = $global:maad_credential_store
        $available_credentials = Get-Content $credential_file_path | ConvertFrom-Json
    }
    catch {
        MAADWriteError "MCS -> Can't Access Credential Store"
    }

    if ($null -ne $available_credentials){
        MAADWriteProcess "MCS -> Listing Credentials"
        
        #Display available credentials
        $all_credentials = $available_credentials.PSObject.Properties
        $all_credentials |Format-Table -Property @{Label="CID";Expression={$_.Name}}, @{Label="Cred Type";Expression={$_.Value.type}}, @{Label="Username";Expression={$_.Value.username}} -Wrap

        do{
            $retrived_creds = $false
            MAADWriteInfo "Select CID to choose credential"
            MAADWriteInfo "Enter [X] to manually enter credential"
            $credential_choice = Read-Host -Prompt "`n[?] Enter Credential (CID / x)"
            Write-Host ""
            if ($credential_choice -in "x") {
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
        MAADWriteProcess "X -> Manual credential input"
        $global:current_username = Read-Host -Prompt "`n[?] Enter Username"
        $global:current_secure_pass = Read-Host -Prompt "`n[?] Enter Password [$global:current_username]" -AsSecureString 
        Write-Host ""
        $global:current_credentials = New-Object System.Management.Automation.PSCredential -ArgumentList ($global:current_username, $global:current_secure_pass)
        MAADWriteInfo "MCS -> Use 'ADD CREDS' to Save Credentials"
    }
    else {
        MAADWriteProcess "MCS -> Retrieved Credential"
        $global:current_secure_pass = ConvertTo-SecureString $global:current_password -AsPlainText -Force
        $global:current_credentials = New-Object System.Management.Automation.PSCredential -ArgumentList ($global:current_username, $global:current_secure_pass)
    }
}