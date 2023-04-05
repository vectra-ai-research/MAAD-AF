<#
.SYNOPSIS
    This file maintains global config for various MAAD-AF modules. 

.NOTES
    Configurations in this file are optional and not required for primary operation of MAAD-AF with the exception of TOR module. 
    1. Add credentials to $CredentialList if you would like to reuse them often. You can add multiple credntials and you can choose one directly for access in MAAD-AF.
    Access token in credentials is optional (if they are provided, MAAD-AF will default to establishing access with them first)

    2. Edit the TOR root folder path in the TOR configuration section (other defaults in this config can remain default) if you would like to route MAAD-AF traffic through TOR. 
    Make sure you have TOR installed in your host. If not, you need to install it manually to use MAAD TOR module

.EXAMPLE
Add credntials to $CredentialList in the following format:
$global:CredentialsList = @(@{"username" = "user1@foo.com";"password" = "xyz_zyx";"token"= "123abc"},@{"username" = "user2@foo.com";"password" = "xyz_zyx";"token"=""})
#>

                #####Access credentials#####

#Note: This configuration is totally optional. Add the crompromised credentials to the if you wish to the $global:CredentialsList list below.

$global:CredentialsList = @()

                ############################

                #####TOR Configuration#####

#Enter TOR root folder path
$global:tor_root_directory = "C:\Users\username\sub_folder\Tor Browser"

#The below TOR configuration does not need to be modified unless you would like to or if you are facing any issues
$global:tor_host = "127.0.0.1"  
#Port used by TOR          
$global:tor_port = 9150
#TOR controller port
$global:control_port = 9151

                ###########################