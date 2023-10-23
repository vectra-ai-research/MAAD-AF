#Assign role 
function AssignRole ($target_object_type){
    mitre_details("AssignRole")

    ###Select a target type
    if ($target_object_type -eq "account"){
    #Set a target account
    EnterAccount ("Enter an account to assign role to (user@org.com)")
    $target_account = $global:account_username
    $target_id = (Get-AzureADUser -SearchString $target_account).ObjectId
    }

    elseif ($target_object_type -eq "group"){
        #Set a target group
        EnterGroup("Enter a target group name to assign role to (Leave blank and press enter to recon all groups)")
        $target_group = $global:group_name
        $target_id = (Get-AzureADMSGroup -SearchString $target_group).Id        
    }

    else{
        break
    }

    EnterRole("Enter a role name to assign (Leave blank and press enter to recon all roles)")
    $target_role = $global:role_name
    $role_definition = Get-AzureADMSRoleDefinition -Filter "displayName eq '$target_role'"
    $role_definition_id = $role_definition.Id
    
    #Assign role to target account
    Write-Host "`n$role_definition" -ForegroundColor Gray
    try {
        Write-Host "`nAttempting to assign $target_role role...`n"
        $role_assignment = New-AzureADMSRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $role_definition_id -PrincipalId $target_id
        Start-Sleep -Seconds 10
        Write-Host "`n[Success] Assigned $target_role role to target" -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to assign role" -ForegroundColor Red
    }
}

function AssignManagementRole {
    EnterAccount ("Enter an account to assign role to (user@org.com)")
    $target_account = $global:account_username
    $target_id = (Get-AzureADUser -SearchString $target_account).ObjectId


    EnterManagementRole "Enter a role name to assign (Leave blank and press enter to recon all roles)"
    $target_role = $global:management_role_name

    #Assign role to target account
    try {
        Write-Host "`nAttempting to assign $target_role role...`n" -ForegroundColor Gray
        Add-RoleGroupMember -Identity $target_role -Member $target_account -ErrorAction Stop
        Write-Host "`n[Success] Assigned $target_role role" -ForegroundColor Yellow
    }
    catch {
        Write-Host "`n[Error] Failed to assign role" -ForegroundColor Red
    }

}