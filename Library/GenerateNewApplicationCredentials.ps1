#Create new credentials for application

function GenerateNewApplicationCredentials{
    EnterApplication("Select target application to generate credentials for")
    $target_app = $global:application_name
    $target_app_object_id = (Get-AzureADApplication  -Filter "displayName eq '$target_app'").ObjectId

    #Generate credential and save credentials to file
    try {
        $app_credentials = New-AzureADApplicationPasswordCredential -ObjectId $target_app_object_id
        Start-Sleep -s 5 
        Write-Host "`nApp: $target_app"
        Write-Host "New Secret: $($app_credentials.value)"
        "$target_app :`n $app_credentials" | Out-File -FilePath .\Outputs\Application_Credentials.txt -Append
        Write-Host "`n[Success] New credential generated for $target_app" -ForegroundColor Yellow

        #Save to credential store
        AddCredentials "application" "GNAC_$target_app$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $target_app $app_credentials.value
    }
    catch {
        Write-Host "`n[Error] Failed to generate new credentials for application" -ForegroundColor Red
    }
}