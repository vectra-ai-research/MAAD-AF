function TORAnonymizer ($command){

    if ($command -eq "start") {
        $global:tor_proxy = $false
        
        $inititate_anonymity = Read-Host -Prompt "`nWould you like to keep your traffic anonymous? (Yes/No)"

        if ($inititate_anonymity -notin "No","no","N","n") {
            Write-Host "`n#####################Important Information#####################" @fg_red
            Write-Host "To offer anonymity the tool will attempt to route your traffic through TOR nodes."
            Write-Host "Selecting (Yes) will attempt to hide the source of your traffic by executing TOR and configuring your device to use a proxy(tool can do this automatically)."
            Write-Host "Enabling TOR may result in overall slower network traffic simply due to the nature of it."
            Write-Host "Selecting (No) will not make any changes to your host or network and MAAD-AF will continue as usual."
            Write-Host "Enabling TOR module requires TOR executable installed on your host, if not already installed."
            Write-Host "If you do not have the TOR executable installed on your host please select (No) now to skip using TOR."
            Write-Host "###############################################################" @fg_red
            $inititate_anonymity = Read-Host -Prompt "`nWould you like to continue and establish anonymity? (Yes/No)"
        }
        
        if ($inititate_anonymity -notin "No","no","N","n"){
            mitre_details("TORAnonymizer")
            #Check from global config file if TOR config file has been added by user
            if ($global:tor_root_directory -eq "C:\Users\username\sub_folder\Tor Browser"){
                Write-Host "TOR executable not found on the host!!!" @fg_red
                Write-Host "`nTip:`n1. Check there's have TOR installed on your host. Checkout: https://www.torproject.org/`n2. Update the TOR direcotry path in MAAD_Config.ps1" @fg_gray
                Write-Host "`nNote: MAAD-AF will now continue without TOR!!!"
                return
            }

            Write-Host "Initiating TOR..."
            invoke-expression 'cmd /c start powershell -NoExit -Command  {. .\Library\TORAnonymizer.ps1;TORProxy}'
            Write-Warning "TOR server is initiated in a separate window. Please do not close the window if you want TOR to be running!!!"
            Write-Host "Connecting to TOR nodes..."
            Start-Sleep -Seconds 3

            Write-Host "Configuring Proxy on host to route traffic through TOR..."
            try {
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "http://127.0.0.1:9150" -ErrorAction Stop
                Write-Host "- Successfully modified keys to add TOR proxy!" @fg_gray
                Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 1 -ErrorAction Stop
                Write-Host "- Successfully modified keys to enable TOR proxy!" @fg_gray
                $global:tor_proxy = $true
            }
            catch {
                Write-Host "Failed to setup proxy for TOR!!!"
                break
            }

            Write-Host "Routing traffic through TOR nodes..."
            Write-Host "Going Dark!!! You are now anonymous!!!" @fg_yellow @bg_black
        }
    }

    if ($command -eq "stop" -and $global:tor_proxy -eq $true) {
        try {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "" -ErrorAction Stop
            Write-Host "`n- Successfully removed TOR proxy!" @fg_gray
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 0 -ErrorAction Stop
            Write-Host "- Successfully disabled proxy!" @fg_gray
            Write-Host "`Successfully reverted all network changes made by the tool!!!`n"
            $global:tor_proxy = $false
        }
        catch {
            Write-Host "Failed to remove proxy for TOR! Check out the guide for instructions on on how to do it manually!!!"
            break
        }
    }
}
function TORProxy {

    #Load proxy user configuration from file
    . ./Library/MAAD_Config.ps1
    
    #set parameters for tor executable
    $tor_exe = "$global:tor_root_directory\Browser\TorBrowser\Tor\tor.exe"
    $torrc_defaults = "$global:tor_root_directory\Browser\TorBrowser\Data\Tor\torrc-defaults"
    $torrc = "$global:tor_root_directory\Browser\TorBrowser\Data\Tor\torrc"
    $tor_data = "$global:tor_root_directory\Browser\TorBrowser\Data\Tor"
    $geo_IP_file = "$global:tor_root_directory\Browser\TorBrowser\Data\Tor\geoip"
    $geo_IPv6_file = "$global:tor_root_directory\Browser\TorBrowser\Data\Tor\geoip6"

    #Run TOR proxy
    Write-Host "Running TOR..." @fg_red
    Write-Host "Hit 'Ctrl+C' to stop Tor!"
    & "$tor_exe" --defaults-torrc $torrc_defaults -f $torrc DataDirectory $tor_data GeoIPFile $geo_IP_file GeoIPv6File $geo_IPv6_file +__ControlPort $global:control_port +__HTTPTunnelPort "${global:tor_host}:$global:tor_port IPv6Traffic PreferIPv6 KeepAliveIsolateSOCKSAuth" __OwningControllerProcess $PID | more
}