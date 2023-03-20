function LaunchPreCompromise {
    $ext_recon_option_list = @{0 = "Main menu"; 1 = "Recon organization/user"; 2 = "Brute force credentials"};
        do{ 
            #Display options
            OptionDisplay "Pre-compromise options:" $ext_recon_option_list
            
            #Take user choice
            while ($true) {
                try {
                    Write-Host "`n"
                    [int]$ext_recon_user_choice = Read-Host -Prompt 'Choose a recon site option:'
                    break
                }
                catch {
                    Write-Host "Invalid input!!! Choose an option number from the list!"
                }
            }
            
            if ($ext_recon_user_choice -eq 1) {
                ExternalRecon
            }

            if ($ext_recon_user_choice -eq 2) {
                ExternalBruteForce
            }

        } while($ext_recon_user_choice -ne 0)
}