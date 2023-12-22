function DisableHostProxy {

    Write-Host ""
    MAADWriteInfo "The TOR module in MAAD-AF configures your host proxy to enable traffic routing via TOR"
    MAADWriteInfo "The proxy configuration is reset automatically if the tool is terminated correctly"
    MAADWriteInfo "In circcumstances when the modified configuration persists, you can use this module to clear any host proxy configuration and disable the use of proxy"

    $user_input = Read-Host "`n[?] Clear & Disable host proxy config (y/n)"
    Write-Host ""

    if ($user_input.ToUpper() -in "YES","Y"){
        try {
            MAADWriteProcess "Disabling host proxy"
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "" -ErrorAction Stop
            MAADWriteProcess "Removed proxy configuration"
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 0 -ErrorAction Stop
            MAADWriteSuccess "Host Proxy Disabled"
            $global:tor_proxy = $false
        }
        catch {
            MAADWriteError "Failed to disable host proxy"
            break
        }
    }
    else{
        MAADWriteProcess "No action executed"
    }
    MAADPause
}


function ModifyMAADDependencyCheck {
    Write-Host ""

    MAADWriteInfo "MAAD-AF checks for external dependencies at every launch"
    MAADWriteInfo "This is not required to run often and can be set to disabled as default using this option to expedite tool initialization"
    Write-Host ""

    #Read MAAD Config
    MAADWriteProcess "Retrieving current DependencyCheckBypass config"
    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json
    $DependecyCheckBypass = $maad_config.DependecyCheckBypass

    #Display current status of bypass
    MAADWriteProcess "DependencyCheckBypass Status -> $DependecyCheckBypass"

    #Depending on the current status of bypass config - display options to user
    if ($DependecyCheckBypass) {
        $user_input = Read-Host -Prompt "`n[?] Disable dependency check bypass (y/n)"
        Write-Host ""
        if ($user_input.ToUpper() -in "Yes","Y") {
            $maad_config.DependecyCheckBypass = $false

            #Update MAAD Config
            $maad_config_json = $maad_config | ConvertTo-Json
            $maad_config_json | Set-Content -Path $global:maad_config_path -Force

            MAADWriteProcess "Retrieving updated dependency check bypass default config"
            MAADWriteProcess "Default: DependencyCheckBypass -> Disabled"
        }
    }
    else {
        MAADWriteProcess "Setting bypass to [Enable] as default to skip dependency check at initialization. You can re-enable it by using this option again"
        $user_input = Read-Host -Prompt "`n[?] Enable dependency check bypass (y/n)"
        Write-Host ""
        if ($user_input.ToUpper() -in "Yes","Y") {
            $maad_config.DependecyCheckBypass = $true

            #Update MAAD Config
            $maad_config_json = $maad_config | ConvertTo-Json
            $maad_config_json | Set-Content -Path $global:maad_config_path -Force

            MAADWriteProcess "Retrieving updated dependency check bypass default config"
            MAADWriteProcess "Default: DependencyCheckBypass -> Enabled"
        }
    }
    MAADPause
    
}

function ModifyMAADTORConfig {
    #Read MAAD Config
    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json
    $tor_root_directory = $maad_config.tor_config.tor_root_directory
    $tor_host = $maad_config.tor_config.tor_host
    $tor_port = $maad_config.tor_config.tor_port
    $tor_control_port = $maad_config.tor_config.control_port

    #Display current config
    MAADWriteProcess "Retrieving current MAAD-AF TOR Config"
    if ($tor_root_directory -in $null, "C:\Users\username\sub_folder\Tor Browser") {
        MAADWriteProcess "TOR Root Directory: Not Set"
    }
    else {
        MAADWriteProcess "TOR Root Directory: $tor_root_directory"
    }
    if ($null -eq $tor_host) {
        MAADWriteProcess "TOR Host: Not Set"
    }
    else {
        MAADWriteProcess "TOR Host: $tor_host"
    }
    if ($null -eq $tor_port) {
        MAADWriteProcess "TOR Port: Not Set"
    }
    else {
        MAADWriteProcess "TOR Port: $tor_port"
    }
    if ($null -eq $tor_control_port) {
        MAADWriteProcess "TOR Control Port: Not Set"
    }
    else {
        MAADWriteProcess "TOR Control Port: $tor_control_port"
    }

    #Configure with user inputs
    $new_tor_root_directory = Read-Host -Prompt "`n[?] Set TOR root directory (absolute path of TOR directory on your host)" 
    $new_tor_host = Read-Host -Prompt "`n[?] Set TOR host address (suggested: 127.0.0.1)"
    $new_tor_port = Read-Host -Prompt "`n[?] Set TOR port (suggested: 9150)"
    $new_tor_control_port = Read-Host -Prompt "`n[?] Set TOR control port (suggested: 9151)"

    $maad_config.tor_config.tor_root_directory = $new_tor_root_directory
    if ($new_tor_host -notin $null,"") {
        $maad_config.tor_config.tor_host = $new_tor_host
    }

    if ($new_tor_port -notin $null,"") {
        $maad_config.tor_config.tor_port = $new_tor_port
    }

    if ($new_tor_control_port -notin $null,"") {
        $maad_config.tor_config.control_port = $new_tor_control_port
    }
    
    #Update MAAD Config
    MAADWriteProcess "Updating MAAD-AF TOR config"
    $maad_config_json = $maad_config | ConvertTo-Json
    $maad_config_json | Set-Content -Path $global:maad_config_path -Force
    
    MAADWriteSuccess "MAAD-AF TOR Config Updated"
    MAADPause
}
