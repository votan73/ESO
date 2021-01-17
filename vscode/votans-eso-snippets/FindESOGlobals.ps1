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
$APIVersion = "100033", "100034"

$UTF8BOM = [System.Text.Encoding]::UTF8.GetPreamble()
$win1252 = [System.Text.Encoding]::GetEncoding(1252)

$keywords = [System.Collections.Generic.HashSet[string]]::new()
function AddKeyword($word) {
    $x = $keywords.Add($word)
}
<#
AddKeyword("_G")
AddKeyword("AddCustomMenuItem")
AddKeyword("AddMenuItem")
AddKeyword("ApplyTemplateToControl")
AddKeyword("assert")
AddKeyword("ClearMenu")
AddKeyword("collectgarbage")
AddKeyword("debug")
AddKeyword("error")
AddKeyword("ESO_Dialogs")
AddKeyword("GetControl")
AddKeyword("GetInterfaceColor")
AddKeyword("getmetatable")
AddKeyword("GetString")
AddKeyword("GuiRoot")
AddKeyword("internalassert")
AddKeyword("ipairs")
AddKeyword("math")
AddKeyword("next")
AddKeyword("os")
AddKeyword("pairs")
AddKeyword("pcall")
AddKeyword("PlaySound")
AddKeyword("rawset")
AddKeyword("select")
AddKeyword("setmetatable")
AddKeyword("ShowMenu")
AddKeyword("string")
AddKeyword("table")
AddKeyword("tonumber")
AddKeyword("tostring")
AddKeyword("type")
AddKeyword("unpack")
AddKeyword("zo_clamp")
AddKeyword("zo_max")
AddKeyword("zo_min")
AddKeyword("zo_strformat")
#>

$globals = New-Object System.Collections.Generic.HashSet[string]

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
        foreach($line in $o){
            $match = [regex]::Match($line, "\[(?<line>\d+)\]\s+(?<global>.ETGLOBAL)\s*.+\s*;\s*(?<fn>.+)")
            if ($match.Success) {
                $g = $match.Groups["global"].Value
                $fn = $match.Groups["fn"].Value
                if ($keywords.Contains($fn)) { continue }
                $x = $globals.Add($fn)
            }
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
            $source += "local function f$count(self, ...)`r`n"
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

Set-Location -Path $root.FullName

$files = $addonsFolder.GetFiles("*.lua", "AllDirectories")
$files += $addonsFolder.GetFiles("*.xml", "AllDirectories")
$luaFiles = @()
$xmlFiles = @()
foreach($fileInfo in $files) {
    $fileName = $fileInfo.Fullname
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

$stringIdentifier = New-Object System.Collections.Generic.List[string]
foreach($word in $globals) {
    if ($word.StartsWith("SI_") -and $word.ToUpper().Equals($word) ) {
        $x = $stringIdentifier.Add($word)
    }
}
$stringIdentifier.Sort()
$globals.ExceptWith($stringIdentifier)

$events = New-Object System.Collections.Generic.List[string]
foreach($word in $globals) {
    if ($word.StartsWith("EVENT_") -and $word.ToUpper().Equals($word) ) {
        $x = $events.Add($word)
    }
}
$events.Sort()
$globals.ExceptWith($events)

$fragments = New-Object System.Collections.Generic.List[string]
foreach($word in $globals) {
    if ($word.EndsWith("_FRAGMENT") -and $word.ToUpper().Equals($word) ) {
        $x = $fragments.Add($word)
    }
}
$fragments.Sort()
$globals.ExceptWith($fragments)

$scenes = New-Object System.Collections.Generic.List[string]
foreach($word in $globals) {
    if ($word.EndsWith("_SCENE") -and $word.ToUpper().Equals($word) ) {
        $x = $scenes.Add($word)
    }
}
$scenes.Sort()
$globals.ExceptWith($scenes)

$manager = New-Object System.Collections.Generic.List[string]
foreach($word in $globals) {
    if ($word.Contains("_MANAGER") -and !$word.StartsWith("SI_")) {
        $x = $manager.Add($word)
    }
}
$manager.Sort()
$globals.ExceptWith($manager)
$globals

$snippnetFile = "snippets\eso-snippets.code-snippets"
$json = ConvertFrom-Json -InputObject (Get-Content -Path $snippnetFile -Raw -Encoding UTF8)

$json|Add-Member "ESO Manager Instances" -Value @{} -MemberType NoteProperty -ErrorAction SilentlyContinue

$snippet = $json.'ESO Manager Instances'
$snippet.'prefix' = "!esoManager"
$snippet.'body' = ("`${1|" + [String]::Join(",", $manager) + "|}")
$snippet.'description' = "ESO Manager Instances"
$snippet.'scope' = "lua"

$json|Add-Member "ESO Client Events" -Value @{} -MemberType NoteProperty -ErrorAction SilentlyContinue

for($i=0; $i -lt $events.Count;$i++) { $events[$i] = $events[$i].Substring(6) }

$snippet = $json.'ESO Client Events'
$snippet.'prefix' = "!esoEvent"
$snippet.'body' = ("EVENT_`${1|" + [String]::Join(",", $events) + "|}")
$snippet.'description' = "ESO events from C++ client"
$snippet.'scope' = "lua"

$json|Add-Member "ESO Scenes" -Value @{} -MemberType NoteProperty -ErrorAction SilentlyContinue

for($i=0; $i -lt $scenes.Count;$i++) { $scenes[$i] = $scenes[$i].Replace("_SCENE", "") }

$snippet = $json.'ESO Scenes'
$snippet.'prefix' = "!esoScene"
$snippet.'body' = ("`${1|" + [String]::Join(",", $scenes) + "|}_SCENE")
$snippet.'description' = "ESO Scenes"
$snippet.'scope' = "lua"

$json|Add-Member "ESO Fragments" -Value @{} -MemberType NoteProperty -ErrorAction SilentlyContinue

for($i=0; $i -lt $fragments.Count;$i++) { $fragments[$i] = $fragments[$i].Replace("_FRAGMENT", "") }

$snippet = $json.'ESO Fragments'
$snippet.'prefix' = "!esoFragments"
$snippet.'body' = ("`${1|" + [String]::Join(",", $fragments) + "|}_FRAGMENT")
$snippet.'description' = "ESO Fragments"
$snippet.'scope' = "lua"

Set-Content -Path $snippnetFile -Value (ConvertTo-Json -InputObject $json -Compress) -Encoding UTF8
