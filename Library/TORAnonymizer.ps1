function TORAnonymizer ($command){

    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json
    $tor_root_directory = $maad_config.tor_config.tor_root_directory

    if ($command -eq "start") {
        $global:tor_proxy = $false
        
        $inititate_anonymity = Read-Host -Prompt "`nWould you like to keep your traffic anonymous? (Yes/No)"

        if ($inititate_anonymity -notin "No","no","N","n") {
            Write-Host "`n#####################Important Information#####################" -ForegroundColor Gray
            Write-Host "To offer anonymity the tool will attempt to route your traffic through TOR nodes." -ForegroundColor Gray
            Write-Host "Selecting (Yes) will attempt to hide the source of your traffic by executing TOR and configuring your device to use a proxy(tool can do this automatically)." -ForegroundColor Gray
            Write-Host "Enabling TOR may result in overall slower network traffic simply due to the nature of it." -ForegroundColor Gray
            Write-Host "Selecting (No) will not make any changes to your host or network and MAAD-AF will continue as usual." -ForegroundColor Gray
            Write-Host "Enabling TOR module requires TOR executable installed on your host, if not already installed." -ForegroundColor Gray
            Write-Host "If you do not have the TOR executable installed on your host please select (No) now to skip using TOR." -ForegroundColor Gray
            Write-Host "###############################################################" -ForegroundColor Gray
            $inititate_anonymity = Read-Host -Prompt "`nWould you like to continue and establish anonymity? (Yes/No)"
        }
        
        if ($inititate_anonymity -notin "No","no","N","n"){
            mitre_details("TORAnonymizer")
            #Check from local config file if TOR config has been updated by user
            if ($tor_root_directory -eq "C:\Users\username\sub_folder\Tor Browser"){
                Write-Host "TOR executable not found on the host!!!" -ForegroundColor Red
                Write-Host "`n[Tip]`n1. Check that TOR is installed on your host. Checkout: https://www.torproject.org/`n2. Update the TOR direcotry path in MAAD_Config.ps1" -ForegroundColor Gray
                Write-Host "`nMAAD-AF will now continue without TOR" -ForegroundColor Gray
                return
            }

            Write-Host "Initiating TOR..." -ForegroundColor Gray
            invoke-expression 'cmd /c start powershell -NoExit -Command  {. .\Library\TORAnonymizer.ps1;TORProxy}'
            Write-Warning "TOR server is initiated in a separate window. Please do not close the window if you want TOR to be running!!!"
            Write-Host "Connecting to TOR nodes..." -ForegroundColor Gray
            Start-Sleep -Seconds 3

            Write-Host "`nConfiguring Proxy on host to route traffic through TOR..." -ForegroundColor Gray
            try {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "http://127.0.0.1:9150" -ErrorAction Stop
                Write-Host "Modified keys to add TOR proxy" -ForegroundColor Gray
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 1 -ErrorAction Stop
                Write-Host "Modified keys to enable TOR proxy" -ForegroundColor Gray
                $global:tor_proxy = $true
            }
            catch {
                Write-Host "[Error] Failed to setup proxy for TOR" -ForegroundColor Red
                break
            }

            Write-Host "`nRouting traffic through TOR nodes..." -ForegroundColor Gray
            Write-Host "[TOR Active] Going Dark - You are now anonymous" -ForegroundColor Yellow
            Write-MAADLog "START" "TOR started"
        }
    }

    if ($command -eq "stop" -and $global:tor_proxy -eq $true) {
        DisableHostProxy
        Write-MAADLog "STOP" "TOR stopped"
    }
}
function TORProxy {
    #Load local proxy configuration from maad_config
    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json

    $control_port = $maad_config.tor_config.control_port
    $tor_root_directory = $maad_config.tor_config.tor_root_directory
    $tor_host = $maad_config.tor_config.tor_host
    $tor_port = $maad_config.tor_config.tor_port
    
    #set parameters for tor executable
    $tor_exe = "tor_root_directory\Browser\TorBrowser\Tor\tor.exe"
    $torrc_defaults = "$tor_root_directory\Browser\TorBrowser\Data\Tor\torrc-defaults"
    $torrc = "$tor_root_directory\Browser\TorBrowser\Data\Tor\torrc"
    $tor_data = "$tor_root_directory\Browser\TorBrowser\Data\Tor"
    $geo_IP_file = "$tor_root_directory\Browser\TorBrowser\Data\Tor\geoip"
    $geo_IPv6_file = "$tor_root_directory\Browser\TorBrowser\Data\Tor\geoip6"

    #Run TOR proxy
    Write-Host "`nRunning TOR..." -ForegroundColor Gray
    Write-Host "`nHit 'Ctrl+C' to stop Tor!" -ForegroundColor Gray
    & "$tor_exe" --defaults-torrc $torrc_defaults -f $torrc DataDirectory $tor_data GeoIPFile $geo_IP_file GeoIPv6File $geo_IPv6_file +__ControlPort $control_port +__HTTPTunnelPort "${tor_host}:$tor_port IPv6Traffic PreferIPv6 KeepAliveIsolateSOCKSAuth" __OwningControllerProcess $PID | more
}