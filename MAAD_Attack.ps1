<#
.SYNOPSIS
    Attack tool to exploit Microsoft 365 and Entra ID(Azure AD) services & configurations to emulate attacker behavior in a compromised Microsoft cloud environment.

.DESCRIPTION
    MAAD-AF is designed for security teams to test their cloud security controls, detection & response capabilities easily and swiftly. MAAD-AF intends to make cloud security testing simple, fast, and effective for security practitioners by providing an intuitive testing tool focused on prevalent attacker tactics & techniques.
    This tool is intended to be used for education purposes, for testing your OWN M365/AzureAD environments or one you are AUTHORIZED to test.
    Please refrain from using the tool if you have any questions or concerns about its impact on your cloud environment.
    Many changes made by this tool can be reversed and the tool offers options to automatically revert most of the changes it does. However, please take any action at your own risk. 

.EXAMPLE
    The example below shows how to execute the tool:
     .\MAAD_Attack.ps1

.NOTES
    Author: Arpan Sarkar (@openrec0n)
    Version: 2.0
#>

##Unblock module files before loading them
Unblock-File -Path ./Library/*
#Import All MAAD Functions from MAAD Library
foreach($maad_function in (Get-ChildItem ./Library/* -Include *.ps1).Name){. ./Library/$maad_function}

#Primary global variables
$global:maad_credential_store = ".\Local\MAAD_Credential_Store.json"
$global:maad_config_path = ".\Local\MAAD_Local_Configuration.json"
$global:maad_log_file = ".\Local\MAAD_AF_Log.txt"

#Initiation message 
MAADInitialization

#Run primary checks for MAAD-AF
InitializationChecks

#Check for Powershell modules required for tool operation
RequiredModules

#Check and Initiate TOR
TORAnonymizer("start")

#Launch MAD-AF Attack Arsenal
MAADAttackArsenal 