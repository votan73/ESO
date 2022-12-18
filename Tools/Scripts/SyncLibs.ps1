param($Path="Z:\live\AddOns")

if ($Path.Length -eq 0){ return }
if (![System.IO.Directory]::Exists($Path)) { return }

$root = Get-Item -Path $Path

function Sync() {
param ([string]$filename, [switch]$controls = $false)

    $files = $root.GetFiles($filename, "AllDirectories")
    $newestDate = [datetime]0
    $newestFile = $null
    foreach($file in $files) {
        if ($file.LastWriteTime -gt $newestDate) {
            $newestFile = $file
            $newestDate = $newestFile.LastWriteTime
        }
    }

    $newestFile

    foreach($file in $files) {
        if ($file -ne $newestFile) {
            if ($controls) {
                foreach($control in $newestFile.Directory.GetDirectories("controls").GetFiles()) {
                    Copy-Item -Path $control.FullName -Destination ([System.IO.Path]::Combine($file.Directory.FullName, "controls", $control.Name)) -Force
                }
            }
            $addonName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $folder = $file.Directory
            if ($folder.Name -eq $addonName) {
                $manifest = $addonName + ".txt"
                Copy-Item -Path ([System.IO.Path]::Combine($newestFile.Directory, $manifest)) -Destination ([System.IO.Path]::Combine($folder, $manifest)) -Force -ErrorAction SilentlyContinue
            }
            Copy-Item -Path $newestFile.FullName -Destination $file.FullName -Force
        }
    }
}

Sync -filename "LibStub.lua"
Sync -filename "LibCustomMenu.lua"
Sync -filename "LibAsync.lua"
Sync -filename "LibHarvensAddonSettings.lua"
Sync -filename "LibGPS.lua"
Sync -filename "LibMapPing.lua"
Sync -filename "LibMapPins-1.0"
Sync -filename "libCommonInventoryFilters.lua"
Sync -filename "LibAddonMenu-2.0.lua" -controls
