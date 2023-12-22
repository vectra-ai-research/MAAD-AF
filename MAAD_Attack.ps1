<#
.SYNOPSIS
    Attack tool to test Microsoft 365 and Entra ID(Azure AD) security by attack emulation.

.DESCRIPTION
    MAAD-AF is designed for security teams to test their Microsoft cloud security controls, detection & response capabilities easily and swiftly. MAAD-AF intends to make cloud security testing simple, fast, and effective for security practitioners by providing an intuitive testing tool focused on prevalent attacker tactics & techniques.
    This tool is intended to be used for education purposes, for testing your OWN M365 / Entra ID environments or one you are AUTHORIZED to test.
    Please refrain from using the tool if you have any questions or concerns about its impact on your cloud environment.
    Many changes executed using techniques in MAAD-AF can be reversed and the tool offers options to automatically revert most of the changes. However, please take any action at your own risk. 

.EXAMPLE
    The example below shows how to execute the tool:
    1. Launch MAAD-AF with default settings
     .\MAAD_Attack.ps1
    
    2. Launch MAAD-AF by bypassing dependency check
     .\MAAD_Attack.ps1 -ForceBypassDependencyCheck

    3. Launch MAAD-AF by forcing dependency check
     .\MAAD_Attack.ps1 -ForceDependencyCheck

.NOTES
    Author: Arpan Sarkar (@openrec0n)
    Version: 3.0
#>
param (
    [switch]$ForceBypassDependencyCheck,
    [switch]$ForceDependencyCheck
)

# Unblock module files before loading them
Unblock-File -Path ./Library/*
# Import All MAAD Functions from MAAD Library
foreach($maad_function in (Get-ChildItem ./Library/* -Include *.ps1).Name){. ./Library/$maad_function}

# Primary global variables
$global:maad_credential_store = ".\Local\MAAD_Credential_Store.json"
$global:maad_config_path = ".\Local\MAAD_AF_Global_Config.json"
$global:maad_log_file = ".\Local\MAAD_AF_Log.txt"

# Initiation message 
MAADInitialization

# Run primary checks for MAAD-AF
InitializationChecks

# Check whether to bypass dependency check or not
# Run check if force check parameter is passed
if ($ForceDependencyCheck) {
    Write-MAADLog "DependencyCheck" "Dependency Check Initialized"
    RequiredModules
}
else {
    # Bypass check if force bypass parameter is passed
    if ($ForceBypassDependencyCheck) {
        Write-MAADLog "DependencyCheck" "Dependency Check Bypassed"
    }
    else {
        #If no command line argument is passed, then check the default MAAD config for bypass definition
        $maad_config = Get-Content $global:maad_config_path | ConvertFrom-Json
        $Default_DependecyCheckBypass = $maad_config.DependecyCheckBypass
        if ($Default_DependecyCheckBypass -eq $false){
            Write-MAADLog "DependencyCheck" "Dependency Check Initialized"
            RequiredModules
        }
        else {
            Write-MAADLog "DependencyCheck" "Dependency Check Bypassed - Default"
        }
    }
}

#Launch MAD-AF Attack Arsenal
MAADAttackArsenal 