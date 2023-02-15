<#
.SYNOPSIS
    Attack tool which exploits Microsoft 365 and Azure AD configurations to emulate attacker behavior in a compromised Microsoft cloud environment.

.DESCRIPTION
    MAAD-AF is designed for security teams to test their cloud security controls, detection & response capabilities easily and swiftly. MAAD-AF intends to make cloud security testing simple, fast, and effective for security practitioners by providing an intuitive testing tool focused on prevalent attacker tactics & techniques.
    This tool is intended to be used for education purposes, for testing your OWN M365/AzureAD environments or one you are AUTHORIZED to test.
    Please refrain from using the tool if you have any questions or concerns about its impact on your environment.
    Most changes made by this tool can be reversed and the tool offers options to automatically revert most of the changes it does. However, please take any action at your own risk. 

.EXAMPLE
    The example below shows how to execute the tool:
     .\MAAD_Attack.ps1

.NOTES
    Author: Arpan Sarkar (@openrec0n)
#>

#Import All MAAD Functions from MAAD Library
foreach($maad_function in (Get-ChildItem ./Library/).Name){. ./Library/$maad_function}

#Initiation message 
MAADInitialization

#Clear any active sessions to prevent reaching session limit
ClearActiveSessions 

#Create outputs directory (if not present)
CreateOutputsDir

#Check for Powershell modules required for tool operation
RequiredModules

#Check and Initiate TOR
TORAnonymizer("start")

###Main Script###
while ($true) {
    #Display primary modes
    Write-Host "`n                    ___MAAD-AF Modes___`n(1)Pre-compromise                  (2)Exploit M365/AzureAD`n" -ForegroundColor Yellow
    
    [int]$mode = Read-Host "Choose mode:"
    switch ($mode) {
        1 {LaunchPreCompromise}
        2 {LaunchExploitMode}
    }    
} 
