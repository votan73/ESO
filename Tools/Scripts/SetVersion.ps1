param($Path="Z:\")

if ($Path.Length -eq 0){ return }
if (![System.IO.Directory]::Exists($Path)) { return }

$ApiVersion = New-Object System.Collections.Generic.HashSet[string]

$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "Live", "Addons"))
#$addonSettings = Get-Item -Path ([System.IO.Path]::Combine($Path, "Live", "Harven"))

$existingAddons = [System.IO.Directory]::GetDirectories($addonSettings.FullName)

$newaddon = New-Object System.Collections.ArrayList

foreach($addon in $existingAddons.GetEnumerator()) {
    $addonName = [System.IO.Path]::GetFileName($addon)
    #if (![System.IO.Directory]::Exists([System.IO.Path]::Combine($addon, ".svn"))) { continue }

    $name = [System.IO.Path]::Combine($addon, $addonName + ".txt")
    $version = ""
    foreach($line in Get-Content -Path $name -ErrorAction SilentlyContinue) {
        if ($line.StartsWith("## Version: ")) {
            if ($line.StartsWith("## Version: ", "OrdinalIgnoreCase")) {
                try {
                    $version = [System.Version]$line.Substring($line.IndexOf(": ") + 2).Trim()
                } catch {
                    break
                }
            }
        } elseif ($line.EndsWith(".lua")) {
            if ($version -eq "") { break }

            $replace = '$1"' + $version + '"'

            $file = [System.IO.Path]::Combine($addon, $line).Replace("/", "\")
            if ([System.IO.File]::Exists($file)) {
                Write-Host $file
                $newaddon.Clear()
                $isUnicode = $false
                try {
                    $changed = $false
                    foreach($code in Get-Content -Path $file -Encoding UTF8) {
                        foreach($c in $code.GetEnumerator()) { if ([int]$c -gt 127) { $isUnicode = $true } }
                        if($code -match '((_|\.|\s)version\s*=\s*\")(\d+\.\d[^\"]+)"') {
                            write-host $code
                            $changed = $true
                        }
                        $_ = $newaddon.Add(($code -replace '((_|\.|\s)version\s*=\s*)\"(\d+\.\d[^\"]+)\"', $replace))
                    }
                    if ($changed) {
                        write-host $file
                        if ($isUnicode) {
                            Set-Content -Path $file -Value $newaddon -Encoding UTF8
                        } else {
                            Set-Content -Path $file -Value $newaddon -Encoding Default
                        }
                    }
                }
                catch {
                    Write-Host "mist"
                }
            }
        }
    }
}
