param($Path="Z:\")

if ($Path.Length -eq 0){ return }
if (![System.IO.Directory]::Exists($Path)) { return }

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

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "ForApiBump", "AddOns"))

$existingAddons = [System.IO.Directory]::GetDirectories($addonSettings.FullName, "*", "AllDirectories")
$versions = @{}

foreach($addon in $existingAddons.GetEnumerator()) {
    $addonName = [System.IO.Path]::GetFileName($addon)
    $name = [System.IO.Path]::Combine($addon, $addonName + ".txt")
    if (![System.IO.File]::Exists($name)) { continue }
    foreach($line in Get-Content -Path $name) {
        if ($line.StartsWith("## Version: ", "OrdinalIgnoreCase")) {
            try {
                $version = [System.Version]$line.Substring($line.IndexOf(": ") + 2).Trim()
                if ($version.Build -ge 0) {
                    if ($version.Revision -ge 0) {
                        $version = New-Object System.Version -ArgumentList @($version.Major, $version.Minor, $version.Build, ($version.Revision + 1))
                    } else {
                        $version = New-Object System.Version -ArgumentList @($version.Major, $version.Minor, ($version.Build + 1))
                    }
                } else {
                    $version = New-Object System.Version -ArgumentList @($version.Major, $version.Minor, 1)
                }
                $versions[$addonName] = $version
            } catch {
            }
        }
    }
}

$newaddonList = New-Object System.Collections.ArrayList

foreach($addon in $existingAddons.GetEnumerator()) {
    $addonName = [System.IO.Path]::GetFileName($addon)
    $newaddonList.Clear()
    $name = [System.IO.Path]::Combine($addon, $addonName + ".txt")
    $needUpdate = $true
    try {
        if (![System.IO.File]::Exists($name)) { continue }

        foreach($line in Get-Content -Path $name) {
            if (!$line.StartsWith("## APIVersion: ")) {
                if ($line.StartsWith("## Version: ", "OrdinalIgnoreCase") -and $versions.ContainsKey($addonName)) {
                    $version = [System.Version]$line.Substring($line.IndexOf(": ") + 2).Trim()
                    if ($version -lt $versions[$addonName]) {
                        $_ = $newaddonList.Add("## Version: " + $versions[$addonName])
                    } else {
                        $_ = $newaddonList.Add($line)
                    }
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
