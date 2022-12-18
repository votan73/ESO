param($Path=".", [switch]$OmitReferences=$false, [switch]$ParseXml=$false, $Compiler=$null)

# need luac
# download lua-5.1.5_Win32_bin or lua-5.1.5_Win64_bin, e.g. from http://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/
# unpack and copy containing files to script location

if ($Compiler -ne $null) {
    $luac = Get-Item -Path $Compiler -ErrorAction Stop
} else {
    $root = Get-Item -Path $PSScriptRoot
    $luac = $root.GetFiles("luac*.exe")
    if (!$luac.Exists){
        write-host "Lua compiler not found in" $root.Fullname
        return
    }
}
$luac = $luac.FullName

$languages = "en", "fr", "de", "es", "pl", "pt", "ru", "it", "br", "zh", "jp"
$APIVersion = "101034", "101035"

$UTF8BOM = [System.Text.Encoding]::UTF8.GetPreamble()
$win1252 = [System.Text.Encoding]::GetEncoding(1252)

function StripBOM($file) {
    [byte[]] $BOM = [System.IO.File]::ReadAllBytes($file)
    $isUTF8 = $true
    for($i=1; $i -lt $UTF8BOM.Length; $i++) {
        if ($BOM[$i] -ne $UTF8BOM[$i]) {
            $isUTF8 = $false
            break
        }
    }
    if ($isUTF8) {
        $ansi = $win1252.GetString($BOM[3..$BOM.Length])
        $file = [System.IO.Path]::Combine($root.FullName, "temp.lua")
        $ansi
    }
    else {
        $win1252.GetString($BOM)
    }
    $isUTF8
}

function Parse($source) {
    $file = [System.IO.Path]::Combine($root.FullName, "temp.lua")
    Set-Content -Path $file -Value $source

  try{
    $args = @()
    $args += "-p"
    $args += "-l"
    $args += $file

    $o = &$luac $args 2>&1
    if ($LASTEXITCODE -ne 0) {
        ("[ERROR] " + $o.Exception.Message.Substring($o.Exception.Message.IndexOf("temp.lua") + 9))
    }
    else {
        $listSet = [string[]]@()
        $listGet = [string[]]@()
    
        foreach($line in $o){
            $match = [regex]::Match($line, "\[(?<line>\d+)\]\s+(?<global>.ETGLOBAL)\s*.+\s*;\s*(?<fn>.+)")
            if ($match.Success) {
                $g = $match.Groups["global"].Value
                $row = $match.Groups["line"].Value.PadLeft(8) + " " + $match.Groups["fn"].Value
                if ($g -eq "GETGLOBAL") {
                    $listGet += "? $row"
                }
                elseif ($g -eq "SETGLOBAL") {
                    $listSet += "+ $row"
                }
            }
        }
        [array]::Sort($listSet)
        $listSet
        if (!$OmitReferences) {
            [array]::Sort($listGet)
            $listGet
        }
    }
  } finally {
    Remove-Item -Path $file
  }
}
function ParseXml($xml) {
    $xml = [xml]$xml
    $source = ""
    $count = 0
    if ($xml.SelectSingleNode("GuiXml") -ne $null){
        foreach($node in $xml.SelectNodes("//*/text()")){
            $count = $count + 1
            $source += "local function f$count(self)`r`n"
            $source += $node.InnerText.Trim() + "`r`n"
            $source += "end`r`n"
        }
    }
    elseif ($xml.SelectSingleNode("Bindings") -ne $null){
        foreach($node in $xml.SelectNodes("//*/text()")){
            $count = $count + 1
            $source += "local function f$count(keybind)`r`n"
            $source += $node.InnerText.Trim() + "`r`n"
            $source += "end`r`n"
        }
    }
    $lineNum = 0
    $newSource = [string[]]@()
    foreach($line in $source.Replace("`r", "").Split("`n")) {
        if ($line.Length -gt 0) {
            $lineNum = $lineNum + 1
            Write-Output ([String]::Join(" ", $lineNum.ToString().PadLeft(4), $line))
            $newSource += $line
        }
    }
    $source = [String]::Join("`r`n", $newSource)
    Parse($source)
}

$addonsFolder = Get-Item -Path $Path
Set-Location -Path $addonsFolder.FullName
[System.IO.Directory]::SetCurrentDirectory($addonsFolder.FullName)
$rootUri = $addonsFolder.FullName
if (!$rootUri.EndsWith("\\")) { $rootUri+="\" }
$rootUri = [uri] $rootUri

function validateManifest {
    param($manifests, $nested=$false)

    foreach($manifest in $manifests) {
        $addonName = [System.IO.Path]::GetFileNameWithoutExtension($manifest)
        if ($manifest.Directory.Name -ne $addonName) { continue }

        Write-Output ("`nParse manifest " + $manifest.FullName)
        $content = Get-Content -Path $manifest.FullName
        $isManifest = $false
        $files = @()
        $isLanguage = @{}
        foreach($line in $content) {
            if ([regex]::Match($line, "^\w.*(\.lua|\.xml)\s*$", "IgnoreCase").Success) {
                $isManifest = $true

                if ($line.TrimEnd() -ne $line) {
                    Write-Output "[WARN] Manifest filename line has trailing whitespace. `"$line`""
                }

                $fileName = [System.IO.Path]::Combine($manifest.Directory.FullName, $line.TrimEnd().Replace("/", "\"))
                if ($fileName.Contains("`$(language)")) {
                    foreach($lang in $languages) {
                        foreach($api in $APIVersion) {
                            $name = $fileName.Replace("`$(language)", $lang).Replace("`$(APIVersion)", $api)
                            if (!$isLanguage.ContainsKey($name)) {
                                $files += $name
                                $isLanguage[$name] = $true
                            }
                        }
                    }
                } else {
                    foreach($api in $APIVersion) {
                        $name = $fileName.Replace("`$(APIVersion)", $api)
                        if (!$isLanguage.ContainsKey($name)) {
                            $files += $name
                            $isLanguage[$name] = $false
                        }
                    }
                }
            }
        }
        if ($isManifest) {
            $luaFiles = @()
            $xmlFiles = @()
            foreach($fileName in $files) {
                if (![System.IO.File]::Exists($fileName)) {
                    if ($isLanguage[$fileName]) {
                        Write-Output "Language file not found. `"$fileName`""
                    } else {
                        Write-Output "[WARN] File not found. `"$fileName`""
                    }
                }
                else {
                    $source, $isUTF8 = StripBOM $fileName
                    if ($isUTF8) {
                        Write-Output "[INFO] File has utf-8 BOM. Tolerated by ESO, not by luac: $fileName"
                    }
                    if ($fileName.EndsWith(".xml", "OrdinalIgnoreCase")) {
                        $xmlFiles += , ($rootUri.MakeRelativeUri($fileName).ToString(), $source)
                    } else {
                        $luaFiles += , ($rootUri.MakeRelativeUri($fileName).ToString(), $source)
                    }
                }
            }

            foreach($file in $luaFiles){
                Write-Output ("`n" + $file[0])
                Parse $file[1]
            }
            if ($ParseXml) {
                foreach($file in $xmlFiles){
                    Write-Output ("`n" + $file[0])
                    ParseXml $file[1]
                }
            }
        }
    }
}

$manifests = $addonsFolder.GetFiles("*.txt", "AllDirectories")

validateManifest -manifests @($manifests | Where-Object {
    $folder = $_.Directory.FullName
    foreach($other in $manifests) {
        if ($other -ne $_ -and $folder.StartsWith($other.Directory.FullName)) {
            $false
            return
        }
    }
    $true
})

Set-Location -Path $root.FullName
