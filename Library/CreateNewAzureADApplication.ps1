#Create new Azure AD Application
function CreateNewAzureADApplication{
    [string]$new_app_display_name = Read-Host "Enter a display name for the new application"
    try {
        New-AzureADApplication -DisplayName $new_app_display_name
        Write-Host "`n[Success] Created new application: $new_app_display_name" -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "`n[Error] Failed to create new application" -ForegroundColor Red
    }

    if ($allow_undo -eq $true){
        Write-Host "`n"
        $user_confirm = Read-Host -Prompt "`nWould you like to undo changes by deleting the new application? (yes/no)"

        if ($user_confirm -notin "No","no","N","n") {
            try {
                $new_app_id = (Get-AzureADApplication -Filter "displayName eq '$new_app_display_name'").ObjectId
                Remove-AzureADApplication -ObjectId $new_app_id
                Write-Host "`n[Undo Success] Removed new application" -ForegroundColor Yellow
            }
            catch {
                Write-Host "`n[Undo Error] Failed to delete the new application" -ForegroundColor Red
            }
        }
    }
}