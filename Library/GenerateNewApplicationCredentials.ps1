#Create new credentials for application

function GenerateNewApplicationCredentials{
    EnterApplication("`n[?] Enter Application name to generate credential for")
    $target_app = $global:application_name
    $target_app_object_id = (Get-AzureADApplication  -Filter "displayName eq '$target_app'").ObjectId

    #Generate credential and save credentials to file
    try {
        MAADWriteProcess "Attempting to generate new credential" 
        $app_credentials = New-AzureADApplicationPasswordCredential -ObjectId $target_app_object_id
        Start-Sleep -s 5 
        MAADWriteProcess "New secret generated for application"
        
        #Save to credential store
        AddCredentials "application" "GNAC_$target_app$(([DateTimeOffset](Get-Date)).ToUnixTimeSeconds())" $target_app $app_credentials.value
        
        #Save output locally
        "$target_app :`n $app_credentials" | Out-File -FilePath .\Outputs\Application_Credentials.txt -Append
        MAADWriteProcess "Ouput Saved -> \MAAD-AF\Outputs\Application_Credentials.txt" 
        
        #Display output info
        MAADWriteProcess "Application Name: $target_app"
        MAADWriteProcess "New Secret: $($app_credentials.value)"
        MAADWriteSuccess "Application Credentials Generated" 
    }
    catch {
        MAADWriteError "Failed to generate new credentials for application" 
    }
    MAADPause
}