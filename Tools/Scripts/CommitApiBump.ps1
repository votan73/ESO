param($Path="")

if ($Path.Length -eq 0){ return }
if (![System.IO.Directory]::Exists($Path)) { return }

$title = "Flames of Ambition"

$ApiVersion = $null

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "AddOnSettings.txt"))

$newaddonList = New-Object System.Collections.ArrayList
foreach($line in Get-Content -Path $addonSettings.FullName) {
    if ($line.StartsWith("#Version")) {
        $ApiVersion = $line.SubString($line.IndexOf(' ')+1)
        break
    }
}

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "..\ForApiBump\AddOns"))

$existingAddons = [System.IO.Directory]::GetDirectories($addonSettings.FullName)

$text = [System.IO.FileInfo]::new("Text.txt")

$svn = "svn.exe"

foreach($addon in $existingAddons.GetEnumerator()) {
    $addonName = [System.IO.Path]::GetFileName($addon)

    $name = [System.IO.Path]::Combine($addon, $addonName + ".txt")
    $version = $null
    foreach($line in Get-Content -Path $name) {
        if ($line.StartsWith("## Version: ", "OrdinalIgnoreCase")) {
            $version = [System.Version]$line.Substring($line.IndexOf(": ") + 2).Trim()
            break
        }
    }
    if ($version -eq $null) { continue }

    Set-Content -Path $text.FullName -Value ("version $version" + ":`r`n- Update to API $ApiVersion `"$title`".")

    $a = @()
    $a += "info"
    $a += $addon
    $o = &$svn $a 2>&1

    $addon

    if ([String]::Join(" ", $o).indexof("repo:81") -lt 0) {
        "skip"
        continue
    }
    
    $a = @()
    $a += "commit"
    $a += "-F"
    $a += "`"" + $text.FullName + "`""
    $a += $addon
    $a += "--non-interactive"
    $o = &$svn $a 2>&1
    $o
}
