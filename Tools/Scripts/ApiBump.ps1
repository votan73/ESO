param($Path="Z:\Elder Scrolls Online")

if ($Path.Length -eq 0){ return }
if (![System.IO.Directory]::Exists($Path)) { return }

$Token = "5ff8072722ab0c814a37cae55a2fa225d0296a5fdd2cf55e98cc2a5172455337"

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Web.Extensions

$baseUrl = "https://api.esoui.com/addons/"
$listUrl = $baseUrl + "list.json"
$detailsUrlTemplate = $baseUrl + "details/{0}.json"

$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$json.MaxJsonLength = 41457280

$wc = New-Object system.Net.WebClient
$wc.Headers.Add("x-api-token", $Token)

# List addons you have access to
$list = $json.Deserialize($wc.DownloadString($listUrl), [System.Collections.ArrayList])
$nameToVersion = @{}
foreach($addon in $list) {
    $details = $json.Deserialize($wc.DownloadString($addon.details), [System.Collections.ArrayList])
    $nameToVersion[$details.title] = $details.version
}
$ApiVersion = New-Object System.Collections.Generic.HashSet[string]

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "live", "AddOnSettings.txt"))

$newaddonList = New-Object System.Collections.ArrayList
foreach($line in Get-Content -Path $addonSettings.FullName) {
    if ($line.StartsWith("#Version")) {
        $_=$ApiVersion.Add($line.SubString($line.IndexOf(' ')+1))
        break
    }
}

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "pts", "AddOnSettings.txt"))

$newaddonList = New-Object System.Collections.ArrayList
foreach($line in Get-Content -Path $addonSettings.FullName) {
    if ($line.StartsWith("#Version")) {
        $_=$ApiVersion.Add($line.SubString($line.IndexOf(' ')+1))
        break
    }
}

$ApiVersion ="## APIVersion: " + [String]::Join(" ", $ApiVersion)

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "live", "AddOns"))

$existingAddons = [System.IO.Directory]::GetDirectories($addonSettings.FullName, "*", "AllDirectories")

$newaddonList = New-Object System.Collections.ArrayList

foreach($addon in $existingAddons.GetEnumerator()) {
    $addonName = [System.IO.Path]::GetFileName($addon)
    $newaddonList.Clear()
    $name = [System.IO.Path]::Combine($addon, $addonName + ".txt")
    $needUpdate = $true
    try {
        if (![System.IO.File]::Exists($name)) { continue }
        $lines = Get-Content -Path $name
        $title = $null
        foreach($line in $lines) {
            if ($line.StartsWith("## Title: ")) {
                $title = $line.Substring(10)
            }
        }
        if (!$title -or !$nameToVersion.ContainsKey($title)) {
            continue
        }
        $version = [System.Version]$nameToVersion[$title]
        if ($version.Build -ge 0) {
            if ($version.Revision -ge 0) {
                $version = New-Object System.Version -ArgumentList @($version.Major, $version.Minor, $version.Build, ($version.Revision + 1))
            } else {
                $version = New-Object System.Version -ArgumentList @($version.Major, $version.Minor, ($version.Build + 1))
            }
        } else {
            $version = New-Object System.Version -ArgumentList @($version.Major, $version.Minor, 1)
        }

        foreach($line in $lines) {
            if (!$line.StartsWith("## APIVersion: ")) {
                if ($line.StartsWith("## Version: ", "OrdinalIgnoreCase")) {
                    $_ = $newaddonList.Add("## Version: " + $version)
                } else {
                    $_ = $newaddonList.Add($line)
                }
            } else {
                $needUpdate = $line -ne $ApiVersion
                $_ = $newaddonList.Add($ApiVersion)
            }
        }
        if ($needUpdate) {
            Set-Content -Path $name -Value $newaddonList
        }
    } catch {}
}
