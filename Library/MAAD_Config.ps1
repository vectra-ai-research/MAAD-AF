<#
.SYNOPSIS
    This file maintains global config for various MAAD-AF modules. 

.NOTES
    Configurations in this file are optional and not required for primary operation of MAAD-AF modules with the exception of TOR module. 
#>

#####Access credentials#####

#Note: This configuration is totally optional. Set the crompromised credentials here if you wish to not enter them at run time.
$global:AdminUsername = "Enter_Username_Here@domain.com"
$global:AdminPassword = "Enter_Password_Here!"


#####TOR Configuration#####

#Note: Make sure you have TOR installed in your host. If not, you need to install it manually to use MAAD TOR module

#Enter TOR root folder path
$global:tor_root_directory = "C:\Users\username\sub_folder\Tor Browser"

#The below TORconfiguration does not need to be modified unless you would like to or are facing any issues
$global:tor_host = "127.0.0.1"  
#Port used by TOR          
$global:tor_port = 9150
#TOR controller port
$global:control_port = 9151
