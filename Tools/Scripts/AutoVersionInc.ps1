Param([string]$Version = "3.1", [string]$Path="Z:\")

$Token = "5ff8072722ab0c814a37cae55a2fa225d0296a5fdd2cf55e98cc2a5172455337"

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Web.Extensions

$baseUrl = "https://api.esoui.com/addons/"
$listUrl = $baseUrl + "list.json"
$detailsUrlTemplate = $baseUrl + "details/{0}.json"

$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$wc = New-Object system.Net.WebClient
$wc.Headers.Add("x-api-token", $Token)

$needUpdateAddonList = @{}

# List addons you have access to
$list = $json.Deserialize($wc.DownloadString($listUrl), [System.Collections.ArrayList])
foreach($addon in $list) {
    $details = $json.Deserialize($wc.DownloadString($addon.details), [System.Collections.ArrayList])
    if (!($details.compatibility -ccontains $Version)) {
        Write-Host $details.title $details.version
        $needUpdateAddonList[$details.title] = $details
    }
}

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "pts", "Addons"))

$existingAddons = [System.IO.Directory]::GetDirectories($addonSettings.FullName)
foreach($addon in $existingAddons.GetEnumerator()) {
}