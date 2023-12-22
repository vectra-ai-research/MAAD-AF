#Assign role 
function AssignRole ($target_object_type){
    mitre_details("AssignRole")

    ###Select a target type
    if ($target_object_type -eq "account"){
    #Set a target account
    EnterAccount "`n[?] Enter account to assign role (user@org.com)"
    $target_account = $global:account_username
    $target_id = (Get-AzureADUser -SearchString $target_account).ObjectId
    }

    elseif ($target_object_type -eq "group"){
        #Set a target group
        EnterGroup("`n[?] Enter target group name to assign role (press [enter] to find groups)")
        $target_group = $global:group_name
        $target_id = (Get-AzureADMSGroup -SearchString $target_group).Id        
    }

    else{
        break
    }

    EnterRole "`n[?] Enter role name to assign (press [enter] to find roles)"
    $target_role = $global:role_name
    $role_definition = Get-AzureADMSRoleDefinition -Filter "displayName eq '$target_role'"
    $role_definition_id = $role_definition.Id
    
    #Assign role to target account
    try {
        MAADWriteProcess "Attempting to assign role"
        MAADWriteProcess "$target_role -> $target_account"
        $role_assignment = New-AzureADMSRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $role_definition_id -PrincipalId $target_id
        Start-Sleep -Seconds 10
        MAADWriteSuccess "Role Assigned"
        $allow_undo = $true
    }
    catch {
        MAADWriteError "Failed to assign role"
    }
    MAADPause
}

function AssignManagementRole {
    EnterAccount "`n[?] Enter account to assign role (user@org.com)"
    $target_account = $global:account_username
    $target_id = (Get-AzureADUser -SearchString $target_account).ObjectId


    EnterManagementRole "`n[?] Enter role name to assign (press [enter] to find roles)"
    $target_role = $global:management_role_name

    #Assign role to target account
    try {
        MAADWriteProcess "Attempting to assign role"
        MAADWriteProcess "$target_role -> $target_account"
        Add-RoleGroupMember -Identity $target_role -Member $target_account -ErrorAction Stop | Out-Null
        MAADWriteSuccess "Role Assigned"
    }
    catch {
        MAADWriteError "Failed to assign role"
    }
    MAADPause
}