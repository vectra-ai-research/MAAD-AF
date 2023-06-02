function ReconUserGroupRoles {
   #Get all group roles in Azure AD
    $all_roles = Get-AzureADDirectoryRole

    #Get target account
    EnterAccount ("Select an account to recon group roles")
    $target_account = $global:input_user_account
    
    $user_roles = @()

    Write-Host "`nEnumerating through user group roles ..."

    foreach ($role in $all_roles){
        $role_object_id = $role.ObjectId
        if ($target_account -in (Get-AzureADDirectoryRoleMember -ObjectId $role_object_id).UserPrincipalName) {
            #Write-Host "User has role: $($role.DisplayName)"
            $user_roles += $role.DisplayName
        }
    }

    Write-Host "`nFollowing role groups were found for user $target_account :" -ForegroundColor Gray
    $user_roles

    Write-Host "`nUser has: $($user_roles.Count)/$($all_roles.Count)`n" 
}