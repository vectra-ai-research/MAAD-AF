function DisableHostProxy {
    Write-Host "`n###################################### Info ######################################" -ForegroundColor Gray
    Write-Host "`nThe TOR module in MAAD-AF configures your host proxy to enable traffic routing via TOR. `nThis proxy configuration is reset automatically if the tool is terminated correctly. `nIn certain circumstances if the modified configuration persists, you can use this module to clear any host proxy configuration and disable the use of proxy." -ForegroundColor Gray
    Write-Host "`n##################################################################################" -ForegroundColor Gray

    try {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "" -ErrorAction Stop
        Write-Host "`nRemoved proxy configuration!" -ForegroundColor Gray
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 0 -ErrorAction Stop
        Write-Host "`n[Success] Disabled host proxy" -ForegroundColor Yellow
        $global:tor_proxy = $false
    }
    catch {
        Write-Host "`n[Error] Failed to disable host proxy" -ForegroundColor Red
        break
    }
}


function ModifyMAADDependencyCheck {
    Write-Host "`n###################################### Info ######################################" -ForegroundColor Gray
    Write-Host "`nMAAD-AF checks for external dependencies at every launch. `nThis is not required to run often and can be set to disabled as default to expedite tool initialization." -ForegroundColor Gray
    Write-Host "`n##################################################################################" -ForegroundColor Gray

    #Read MAAD Config
    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json
    $DependecyCheckBypass = $maad_config.DependecyCheckBypass

    #Display current status of bypass
    Write-Host "`nDependencyCheckBypass Status: $DependecyCheckBypass" -ForegroundColor Gray

    #Depending on the current status of bypass config - display options to user
    if ($DependecyCheckBypass) {
        $user_input = Read-Host -Prompt "`nDisable dependency check bypass (y/n)"
        if ($user_input.ToUpper() -in "Yes","Y") {
            $maad_config.DependecyCheckBypass = $false

            #Update MAAD Config
            $maad_config_json = $maad_config | ConvertTo-Json
            $maad_config_json | Set-Content -Path $global:maad_config_path -Force

            Write-Host "`n[Success] Dependency check bypass set to disabled by default" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`nSetting bypass to enable as default will skip dependency check at initialization. You can always re-enable it by using this option again" -ForegroundColor Gray
        $user_input = Read-Host -Prompt "`nEnable dependency check bypass (y/n)"
        if ($user_input.ToUpper() -in "Yes","Y") {
            $maad_config.DependecyCheckBypass = $true

            #Update MAAD Config
            $maad_config_json = $maad_config | ConvertTo-Json
            $maad_config_json | Set-Content -Path $global:maad_config_path -Force

            Write-Host "`n[Success] Dependency check bypass set to enabled by default" -ForegroundColor Yellow
        }
    }
    
}

function ModifyMAADTORConfig {
    #Read MAAD Config
    $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json
    $tor_root_directory = $maad_config.tor_config.tor_root_directory
    $tor_host = $maad_config.tor_config.tor_host
    $tor_port = $maad_config.tor_config.tor_port
    $tor_control_port = $maad_config.tor_config.control_port

    #Display current config
    Write-Host "`nCurrent MAAD-AF TOR Config:" -ForegroundColor Gray
    if ($tor_root_directory -in $null, "C:\Users\username\sub_folder\Tor Browser") {
        Write-Host "TOR Root Directory: $tor_root_directory" -ForegroundColor Red
    }
    else {
        Write-Host "TOR Root Directory: $tor_root_directory" -ForegroundColor Gray
    }
    if ($null -eq $tor_host) {
        Write-Host "TOR Host: $tor_host" -ForegroundColor Red
    }
    else {
        Write-Host "TOR Host: $tor_host" -ForegroundColor Gray
    }
    if ($null -eq $tor_port) {
        Write-Host "TOR Port: $tor_port" -ForegroundColor Red
    }
    else {
        Write-Host "TOR Port: $tor_port" -ForegroundColor Gray
    }
    if ($null -eq $tor_control_port) {
        Write-Host "TOR Control Port: $tor_control_port" -ForegroundColor  Red
    }
    else {
        Write-Host "TOR Control Port: $tor_control_port" -ForegroundColor Gray
    }

    #Configure with user inputs
    $new_tor_root_directory = Read-Host -Prompt "`nSet TOR root directory (absolute path of TOR directory on your host)`n" 
    $new_tor_host = Read-Host -Prompt "`nSet TOR host address (default: 127.0.0.1)`n"
    $new_tor_port = Read-Host -Prompt "`nSet TOR port (default: 9150)`n"
    $new_tor_control_port = Read-Host -Prompt "`nSet TOR control port (default: 9151)`n"

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
    $maad_config_json = $maad_config | ConvertTo-Json
    $maad_config_json | Set-Content -Path $global:maad_config_path -Force
    
    Write-Host "`n[Success] Updated MAAD-AF TOR Config" -ForegroundColor Yellow
}
