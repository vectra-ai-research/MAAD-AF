function TORAnonymizer ($command){

    #Read MAAD-AF local config for TOR module
    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json
    $tor_root_directory = $maad_config.tor_config.tor_root_directory
    $tor_host = $maad_config.tor_config.tor_host
    $tor_port = $maad_config.tor_config.tor_port

    if ($command -eq "start") {
        
        $global:tor_proxy = $false
        mitre_details("TORAnonymizer")
  
        MAADWriteInfo "Selecting [y] will attempt to connect to the TOR network"

        $inititate_anonymity = Read-Host -Prompt "`n[?] Connect to TOR network and establish anonymity (y/n)"
        Write-Host ""
 
        if ($inititate_anonymity -notin "No","no","N","n"){
            
            #Check from local config file if TOR config has been updated by user
            if (-Not (Test-Path -Path $tor_root_directory)){
                MAADWriteError "TOR executable not found"
                MAADWriteInfo "Check if TOR is installed on your host"
                MAADWriteInfo "Checkout: https://www.torproject.org/"
                MAADWriteInfo "Update the TOR direcotry path in: $global:maad_config_path"
                Write-Host ""
                MAADPause
                return
            }

            MAADWriteProcess "Initiating TOR"
            invoke-expression 'cmd /c start powershell -NoExit -Command  {. .\Library\TORAnonymizer.ps1; TORProxy}'
            MAADWriteProcess "TOR proxy initialized in new PS window"
            Start-Sleep -Seconds 3

            MAADWriteProcess "Configuring host proxy to route traffic through TOR"
            try {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "$($tor_host):$($tor_port)" -ErrorAction Stop
                MAADWriteProcess "Host keys modified to add TOR proxy"
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 1 -ErrorAction Stop
                MAADWriteProcess "Host keys modified to enable TOR proxy"
                $global:tor_proxy = $true

                MAADWriteProcess "Check TOR PS window to validate TOR is running"
                Write-MAADLog "START" "TOR started"
            }
            catch {
                MAADWriteError "Failed to configure host proxy for TOR"
                break
            } 
            Write-Host ""
            MAADPause  
        }
    }

    if ($command -eq "stop" -and $global:tor_proxy -eq $true) {
        DisableHostProxy
        Write-MAADLog "STOP" "TOR stopped"
    }
}

function TORProxy {
    ###Ths function doesnt use any other MAAD functions because its executed in a separate window
    
    #Load local proxy configuration from maad_config
    $global:maad_config_path = ".\Local\MAAD_AF_Global_Config.json"
    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json

    $control_port = $maad_config.tor_config.control_port
    $tor_root_directory = $maad_config.tor_config.tor_root_directory
    $tor_host = $maad_config.tor_config.tor_host
    $tor_port = $maad_config.tor_config.tor_port
    
    #set parameters for tor executable
    $tor_exe = "$tor_root_directory\Browser\TorBrowser\Tor\tor.exe"
    $torrc_defaults = "$tor_root_directory\Browser\TorBrowser\Data\Tor\torrc-defaults"
    $torrc = "$tor_root_directory\Browser\TorBrowser\Data\Tor\torrc"
    $tor_data = "$tor_root_directory\Browser\TorBrowser\Data\Tor"
    $geo_IP_file = "$tor_root_directory\Browser\TorBrowser\Data\Tor\geoip"
    $geo_IPv6_file = "$tor_root_directory\Browser\TorBrowser\Data\Tor\geoip6"

    #Run TOR proxy
    Write-Host "`n[*] TOR started" -ForegroundColor Gray
    Write-Host "`n[i] Do not close the window if you want TOR running" -ForegroundColor Cyan
    Write-Host "`n[i] Continue using MAAD-AF in the primary terminal" -ForegroundColor Cyan
    Write-Host "`n[i] Press 'Ctrl+C' to stop TOR" -ForegroundColor Cyan
    & "$tor_exe" --defaults-torrc $torrc_defaults -f $torrc DataDirectory $tor_data GeoIPFile $geo_IP_file GeoIPv6File $geo_IPv6_file +__ControlPort $control_port +__HTTPTunnelPort "${tor_host}:$tor_port IPv6Traffic PreferIPv6 KeepAliveIsolateSOCKSAuth" __OwningControllerProcess $PID | more
}