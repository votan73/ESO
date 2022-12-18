Param([string]$Version = "6.2.5")

$Token = "5ff8072722ab0c814a37cae55a2fa225d0296a5fdd2cf55e98cc2a5172455337"

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Web.Extensions

$baseUrl = "https://api.esoui.com/addons/"
$listUrl = $baseUrl + "list.json"
$detailsUrlTemplate = $baseUrl + "details/{0}.json"

$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$json.MaxJsonLength=28388608

$wc = New-Object system.Net.WebClient
$wc.Headers.Add("x-api-token", $Token)

# List addons you have access to
$list = $json.Deserialize($wc.DownloadString($listUrl), [System.Collections.ArrayList])
foreach($addon in $list) {
    $details = $json.Deserialize($wc.DownloadString($addon.details), [System.Collections.ArrayList])
    if (!($details.compatibility -ccontains $Version)) {
        Write-Host $details.title $details.version
    }
}
