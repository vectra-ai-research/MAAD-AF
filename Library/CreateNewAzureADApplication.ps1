#Create new Azure AD Application
function CreateNewAzureADApplication{
    [string]$new_app_display_name = Read-Host "Enter a display name for the new application"
    try {
        New-AzureADApplication -DisplayName $new_app_display_name
        Write-Host "Successfully created new application: $new_app_display_name" -BackgroundColor Black -ForegroundColor Yellow
        $allow_undo = $true
    }
    catch {
        Write-Host "`nFailed to create new application" -ForegroundColor Red
    }

    if ($allow_undo -eq $true){
        try {
            $new_app_id = (Get-AzureADApplication -Filter "displayName eq '$new_app_display_name'").ObjectId
            Remove-AzureADApplication -ObjectId $new_app_id
        }
        catch {
            Write-Host "`nFailed to delete the new application" -ForegroundColor Red
        }
    }
}