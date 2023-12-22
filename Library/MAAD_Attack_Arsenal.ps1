function MAADAttackArsenal{
    $maad_attack_menu = 
    [ordered]@{
        "Pre-Attack" = @{1 = "Find Tenant ID of Organization"; 2 = "Find DNS Info"; 3 = "Recon User Login Info"; 4 = "Check Account Validity in Target Tenant"; 5 = "Enumerate Usernames to Find Valid Users in Tenant"; 6 = "Brute-Force Credentials"};
        "Access" = @{1 = "Show Available Credentials"; 2 = "Add Credentials"; 3 = "Get Access Info"; 4 = "Establish Access - All"; 5 = "Establish Access - AzureAD"; 6 = "Establish Access - Az"; 7 = "Establish Access - Exchange Online"; 8 = "Establish Access - Teams"; 9 = "Establish Access - Msol"; 10 = "Establish Access - Sharepoint Site"; 11 = "Establish Access - Sharepoint Admin Center"; 12 = "Establish Access - Compliance (eDiscovery)"; 13 = "Kill All Access"; 14 = "Anonymize Access with TOR"};
        "Recon" = @{1 = "AAD : Find All Accounts"; 2= "AAD : Find All Groups"; 3 = "AAD : Find All Service Principals"; 4 = "AAD : Find All Auth Policy"; 5 = "AAD : Recon Named Locations"; 6 = "AAD : Recon Conditional Access Policy"; 7 = "AAD : Recon Registered Devices for Account"; 8 = "AAD : Recon All Accessible Tenants"; 9 = "Teams : Recon All Teams"; 10 = "SP : Recon All Sharepoint Sites"; 11 = "Exchange : Find All Mailboxes"; 12 = "AAD : Recon All Directory Roles"; 13 = "AAD : Recon Directory Role Members"; 14 = "AAD : Recon Directory Roles Assigned To User"; 15 = "Exchange : Recon All Role Groups"; 16 = "Exchange : Recon Role Group Members"; 17 = "Exchange : Recon All Management Roles"; 18 = "Exchange : Recon All eDiscovery Admins in Tenant"};
        "Account" = @{1 = "List Accounts in Tenant"; 2 = "Deploy Backdoor Account"; 3 = "Assign Azure AD Role to Account"; 4 = "Assign Management Role Account"; 5 = "Reset Password"; 6 = "Brute-Force Credentials"; 7 = "Disable Account MFA"; 8 = "Delete User"}; 
        "Group" = @{1 = "List Groups in Tenant"; 2 = "Create Group"; 3 = "Add user to Group"; 4 = "Assign Role to Group"};
        "Application" = @{1 = "List Applications in Tenant"; 2 = "Create Application"; 3 = "Generate New Application Credentials"};
        "AzureAD" = @{1 = "Modify Trusted IP Config"; 2 = "Download All Account List"; 3 = "Exploit Cross Tenant Sync"};
        "Exchange" = @{1 = "List Mailboxes in Tenant"; 2 = "Gain Access to Another Mailbox"; 3 = "Setup Email Forwarding"; 4 = "Setup Email Deletion Rule"; 5 = "Disable Mailbox Auditing"; 6 = "Disable Anti-Phishing Policy"};
        "Teams" = @{1 = "List Teams in Tenant"; 2 = "Invite External User to Teams"};
        "Sharepoint" = @{1 = "List Sharepoint Sites"; 2 = "Gain Access to Sharepoint Site"; 3 = "Search Files in Sharepoint"; 4= "Exfiltrate Data from Sharepoint"};
        "Compliance" = @{1 = "Launch New eDiscovery Search"; 2 = "Recon Existing eDiscovery Cases"; 3= "Recon Existing eDiscovery Searches"; 4 = "Find eDiscovery Search Details"; 5 = "Find eDiscovery Case Members"; 6 = "Exfil Data with eDiscovery"; 7 = "Escalate eDiscovery Privileges"; 8 = "Delete compliance case"; 9 = "Install Unified Export Tool"};
        "MAAD-AF" = @{1 = "Set MAAD-AF TOR Configuration"; 2 = "Set Dependency Check Default Setting"; 3 = "Reset & Disable Local Host Proxy Settings"; 4 = "Launch New MAAD-AF Session"};
        "Exit" = @{1 = "Exit - Close all connections"; 2 = "Exit - Keep all connections"}
    }

    while ($true){
        try { 
            do {
                #Display main menu
                DisplayCentre "##########################" "Red"
                DisplayCentre "MAAD Attack Arsenal" "Red"
                DisplayCentre "##########################" "Red"

                $seq = 1
                $main_module_list = @()

                foreach ($item in @($maad_attack_menu.keys)){
                    $main_module_list += [PSCustomObject]@{"seq" = $seq; "Module" = $item}
                    $seq += 1
                }

                #Ref: https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#text-formatting
                
                $main_module_list | Format-Table @{Label="#";Expression={$tf = "4"; $e = [char]27; "$e[${tf}m$($_.seq)${e}[0m"}}, @{Label="MAAD-AF Modules";Expression={$tf = "91"; $e = [char]27; "$e[${tf}m$($_.Module)${e}[0m"}} -HideTableHeaders

                $main_module_user_choice = Read-Host "[?] Select Module"

                #Check for shortcut commands
                switch ($main_module_user_choice.Trim().ToUpper()){
                    "SHOW ALL" {MainMenuExpanded "Attack Arsenal" $maad_attack_menu}
                    "SHOW CREDS" {RetrieveCredentials}
                    "ADD CREDS" {$execution_choice = "Access.2"}
                    "ESTABLISH ACCESS" {EstablishAccess}
                    "SWITCH ACCESS" {EstablishAccess}
                    "ACCESS INFO" {AccessInfo}
                    "KILL ACCESS" {terminate_connection}
                    "ANONYMIZE" {TORAnonymizer("start")}
                    "EXIT" {exit}
                    "FULL EXIT" {terminate_connection;exit}
                    "HELP" {MAADHelp} 
                }
            } while ($main_module_user_choice -notin $main_module_list.seq)

            $selected_module = ($main_module_list | Where-Object {$_.seq -eq [int]$main_module_user_choice}).Module
            $main_module_options = ($maad_attack_menu.$selected_module)
            
            while ($true){
                do {
                    #Display sub-module menu
                    $sub_module_list = @()
                    #add option to go back to main menu
                    $sub_module_list += [PSCustomObject]@{"seq" = 0; "Module" = "Back"}

                    foreach ($item in $main_module_options.GetEnumerator() | sort Name){
                        $sub_module_list += [PSCustomObject]@{"seq" = $item.Name; "Module" = $item.Value}
                    }

                    #Display module selection in sub-menu
                    Write-Host ""
                    Write-Host "Module: $selected_module" -Backgroundcolor DarkRed -ForegroundColor Black

                    $sub_module_list | Format-Table @{Label="#";Expression={$tf = "4"; $e = [char]27; "$e[${tf}m$($_.seq)${e}[0m"}}, @{Label="MAAD-AF Modules";Expression={$tf = "91"; $e = [char]27; "$e[${tf}m$($_.Module)${e}[0m"}} -HideTableHeaders

                    $sub_module_user_choice = Read-Host "[?] Select $selected_module technique"
                    
                } while ($sub_module_user_choice -notin $sub_module_list.seq)
                
                #Option to go back to main menu
                if ($sub_module_user_choice -in 0, $null){
                    break
                }

                $execution_choice = $selected_module +'.'+ [string]$sub_module_user_choice
            
                switch ($execution_choice){
                    "Pre-attack.1" {MAADReconTenantID}
                    "Pre-attack.2" {MAADReconDNSInfo}
                    "Pre-attack.3" {MAADUserLoginInfo}
                    "Pre-attack.4" {MAADCheckUserValidity}
                    "Pre-attack.5" {MAADEnumerateValidUsers}
                    "Pre-attack.6" {ExternalBruteForce}

                    "Access.1" {RetrieveCredentials}
                    "Access.2" {
                        $new_cred_id = Read-Host -Prompt "`n[?] Credential Identifier"
                        $new_cred_type = Read-Host -Prompt "`n[?] Select Cred Type? [password / token]"
                        if ($new_cred_type.Trim() -eq "password"){
                            $new_username = Read-Host -Prompt "`n[?] Username"
                            $new_password = Read-Host -Prompt "`n[?] Password"
                            AddCredentials $new_cred_type $new_cred_id $new_username $new_password 
                        }
                        elseif ($new_cred_type -eq "token"){
                            Read-Host -Prompt "`nToken"
                            AddCredentials $new_cred_type, $new_cred_id $new_token
                        }
                    }
                    "Access.3" {AccessInfo}
                    "Access.4" {EstablishAccess}
                    "Access.5" {EstablishAccess "azure_ad"}
                    "Access.6" {EstablishAccess "az"}
                    "Access.7" {EstablishAccess "exchange_online"}
                    "Access.8" {EstablishAccess "teams"}
                    "Access.9" {EstablishAccess "msol"}
                    "Access.10" {EstablishAccess "sharepoint_site"}
                    "Access.11" {EstablishAccess "sharepoint_admin_center"}
                    "Access.12" {EstablishAccess "ediscovery"}
                    "Access.13" {terminate_connection}
                    "Access.14" {TORAnonymizer("start")}

                    "Recon.1" {MAADGetAllAADUsers}
                    "Recon.2" {MAADGetAllAADGroups}
                    "Recon.3" {MAADGetAllServicePrincipal}
                    "Recon.4" {ListAuthorizationPolicy}
                    "Recon.5" {MAADGetNamedLocations}
                    "Recon.6" {MAADGetConditionalAccessPolicies}
                    "Recon.7" {MAADGetRegisteredDevices}
                    "Recon.8" {MAADGetAccessibleTenants}
                    "Recon.9" {MAADGetAllTeams}
                    "Recon.10" {MAADGetAllSharepointSites}
                    "Recon.11" {MAADGetAllMailboxes}
                    "Recon.12" {MAADGetAllDirectoryRoles}
                    "Recon.13" {MAADGetDirectoryRoleMembers}
                    "Recon.14" {MAADGetAccountDirectoryRoles}
                    "Recon.15" {MAADGetAllRoleGroups}
                    "Recon.16" {MAADGetRoleGroupMembers}
                    "Recon.17" {MAADGetAllManagementRole}
                    "Recon.18" {MAADGetAllEdiscoveryAdmins}

                    "Account.1" {MAADGetAllAADUsers}
                    "Account.2" {CreateAccount}
                    "Account.3" {AssignRole "account"}
                    "Account.4" {AssignManagementRole}
                    "Account.5" {ResetPassword}
                    "Account.6" {InternalBruteForce}
                    "Account.7" {DisableMFA}
                    "Account.8" {RemoveAccess}

                    "Group.1" {MAADGetAllAADGroups}
                    "Group.2" {CreateNewAzureADGroup}
                    "Group.3" {AddObjectToGroup}
                    "Group.4" {AssignRole "group"}

                    "Application.1" {MAADGetAllServicePrincipal}
                    "Application.2" {CreateNewAzureADApplication}
                    "Application.3" {GenerateNewApplicationCredentials}
                    
                    "AzureAD.1" {ModifyTrustedNetworkConfig}
                    "AzureAD.2" {MAADGetAllAADUsers $true}
                    "AzureAD.3" {ExploitCTS}

                    "Exchange.1" {MAADGetAllMailboxes}
                    "Exchange.2" {GrantMailboxAccess}
                    "Exchange.3" {MailForwarding}
                    "Exchange.4" {MailboxDeleteRuleSetup}
                    "Exchange.5" {DisableMailboxAuditing}
                    "Exchange.6" {DisableAntiPhishing}

                    "Teams.1" {MAADGetAllTeams}
                    "Teams.2" {ExternalTeamsInvite}

                    "Sharepoint.1" {MAADGetAllSharepointSites}
                    "Sharepoint.2" {GrantAccessToSharpointSite}
                    "Sharepoint.3" {SearchSharepointSite}
                    "Sharepoint.4" {ExfilDataFromSharepointSite}

                    "Compliance.1" {Create_New_Search}
                    "Compliance.2" {Display_E_Discovery_Cases}
                    "Compliance.3" {
                        Display_E_Discovery_Cases $true
                        if ($null -ne $global:selected_case){
                            Display_E_Discovery_Case_Searches $false $global:selected_case
                        }
                    }
                    "Compliance.4" {
                        #Find Details of a Search
                        Display_E_Discovery_Cases $true
                        
                        if ($null -ne $global:selected_case){
                            Display_E_Discovery_Case_Searches $true $global:selected_case
                        
                            $export_name = $global:selected_search + "_Export"

                            Get-ComplianceSearch -Identity $global:selected_search

                            try {
                                Get-ComplianceSearchAction -Case $global:selected_case -Identity $export_name -IncludeCredential -Details -ErrorAction Stop
                            }
                            catch {
                                Write-Host ""
                                MAADWriteError "No action for this search has been created yet"
                                MAADWriteInfo "Use E-Discovery export module to export this search"
                            }
                        }  
                    }
                    "Compliance.5" {
                        Display_E_Discovery_Cases $true
                        if ($null -ne $global:selected_case){
                            Get-ComplianceCaseMember -Case $global:selected_case -ShowCaseAdmin
                        }
                    }
                    "Compliance.6" {EDiscoveryExfil}
                    "Compliance.7" {E_Discovery_Priv_Esc}
                    "Compliance.8" {DeleteComplianceCase}
                    "Compliance.9" {Install_Unified_Export_Tool}
                    

                    "MAAD-AF.1" {ModifyMAADTORConfig}
                    "MAAD-AF.2" {ModifyMAADDependencyCheck}
                    "MAAD-AF.3" {DisableHostProxy}
                    "MAAD-AF.4" {invoke-expression 'cmd /c start powershell -NoExit -Command  {. .\MAAD_Attack.ps1 -ForceBypassDependencyCheck}'}

                    "Exit.1" {
                        terminate_connection
                        if ($global:tor_proxy = $true) {
                            TORAnonymizer("stop")
                        }
                        MAADWriteProcess "Exiting MAAD-AF"
                        exit
                    }
                    "Exit.2" {exit}
                }
            }
        }
        catch {
            #Do nothing
        }
    }
}

function MainMenuExpanded ($menu_message, $maad_attack_menu){
    $option_list_array = $maad_attack_menu.GetEnumerator()

    foreach ($item in $option_list_array){
        #Display Top category name
        Write-Host $item.Name ":" -ForegroundColor Red

        $sub_module_list = @()
        
        $option_sub_list_array = ($item.Value).GetEnumerator() | sort Name
        foreach ($sub_module in $option_sub_list_array){
            $sub_module_list += [PSCustomObject]@{"seq" = $sub_module.Name; "Module" = $sub_module.Value}
        }

        $sub_module_list | Format-Table @{Label="#";Expression={$tf = "4"; $e = [char]27; "$e[${tf}m$($_.seq)${e}[0m"}}, @{Label="MAAD-AF Modules";Expression={$tf = "91"; $e = [char]27; "$e[${tf}m$($_.Module)${e}[0m"}} -HideTableHeaders
    } 
    MAADPause
}