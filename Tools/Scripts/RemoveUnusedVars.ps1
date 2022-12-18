param($Path="Z:\live")

if ($Path.Length -eq 0){ return }
if (![System.IO.Directory]::Exists($Path)) { return }

$addonList = @{}
$existingAddons = [System.IO.Directory]::GetDirectories([System.IO.Path]::Combine($Path, "Addons"), "*", "AllDirectories")

foreach($addon in $existingAddons.GetEnumerator()) {
    $name = [System.IO.Path]::GetFileName($addon)
    $addonList[$name] = $true
}

$addonSettings = [System.IO.Path]::Combine($Path, "AddOnSettings.txt")
$addonSettings = Get-Item -Path $addonSettings

$newaddonList = New-Object System.Collections.ArrayList
foreach($line in Get-Content -Path $addonSettings.FullName) {
    if (!$line.StartsWith("#")) {
        $name = $line.Substring(0, $line.Length-2)
        if ($addonList[$name]) {
            $_ = $newaddonList.Add($line)
        }
    } else {
        $_ = $newaddonList.Add($line)
    }
}

Set-Content -Path ([System.IO.Path]::Combine($addonSettings.Directory, $addonSettings.Name)) -Value $newaddonList

$addonList.Clear()

foreach($addon in $existingAddons.GetEnumerator()) {
    $name = [System.IO.Path]::Combine($addon, [System.IO.Path]::GetFileName($addon) + ".txt")
    if ([System.IO.File]::Exists($name)) {
        $addonList[[System.IO.Path]::GetFileNameWithoutExtension($addon)] = $true
    }
}

$existingAddons = [System.IO.Directory]::GetFiles([System.IO.Path]::Combine($Path, "SavedVariables"))
foreach($addon in $existingAddons.GetEnumerator()) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($addon)
    if ($name -ne "ZO_Ingame" -and $name -ne "ZO_Pregame" -and $name -ne "ZO_InternalIngame") {
        if (!$addonList[$name]) {
            $addon
            [System.IO.File]::Delete($addon)
        }
    }
}
