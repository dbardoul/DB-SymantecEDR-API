<#
.Synopsis
   Script that will leverage the Symantec EDR API and close all low priority incidents.
.DESCRIPTION
   This script was designed to accomplish something the GUI could not.
   In the EDR web GUI, you cannot close all low priority incidents at once.
   It was a manual process where you could only close so many at a time.
   We had thousands of low priority incidents clogging the EDR database.
.OUTPUTS
   CSV file with list of closed incidents
.NOTES
   Author : Devon Bardoul
   version: 1.0
   Date   : 20-05-2022
#>

$timestamp = $(((get-date).ToUniversalTime()).ToString("yyyyMMddThhmmss"))
$outarray = @()
$username = "<username>"
$password = ConvertTo-SecureString "<password>" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
$tokenResponse = Invoke-RestMethod -Uri 'https://<hostname>.<domain>.local/atpapi/oauth2/tokens' -ContentType 'application/x-www-form-urlencoded' -Authentication 'Basic' -Credential $cred -Method 'POST' -Body 'grant_type=client_credentials&scope=customer'
$token = ConvertTo-SecureString $tokenResponse.access_token -AsPlainText -Force

$url = 'https://<hostname>.<domain>.local/atpapi/v2/incidents'
$type = 'application/json'
$auth = 'Bearer'
$props = @{
    Uri = $url
    ContentType = $type 
    Authentication = $auth
    Token = $token
}

$queryResponse = Invoke-RestMethod @props -Method 'POST' -Body '{"verb":"query","query":"priority_level:1 AND state:1","limit":1000}'
$result = $queryResponse.result

foreach ($r in $result) {
    $uuid = $r.uuid
    $body = '[{"op":"replace","path":' + '"' + "/$uuid/state" + '"' + ',"value":4},{"op":"replace","path":' + '"' + "/$uuid/resolution" + '"' + ',"value":2}]'
    Invoke-RestMethod @props -Method 'PATCH' -Body $body
    $newrow = @{
        "Action" = "Closed";
        "Uuid" = $uuid
    }
    $outarray += $newrow
}

$outarray | Export-Csv "C:\Users\<username>\Desktop\EDR-CloseIncidents_log\$timestamp.csv" -NoTypeInformation