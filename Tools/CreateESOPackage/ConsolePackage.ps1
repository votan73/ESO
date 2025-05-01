param($Path="", [switch]$Upload=$false, [switch]$Test=$false, [switch]$Bundle=$false)

if ($Path.Length -eq 0){ return }
if (![System.IO.Directory]::Exists($Path)) { return }

$targetName = [System.IO.Path]::GetFileName($Path)
if ($targetName.Length -eq 0){ return }

$manifest = [System.IO.Path]::Combine($Path,$targetName+".addon")
if (![System.IO.File]::Exists($manifest)) {
    $manifest = [System.IO.Path]::Combine($Path,$targetName+".txt")
}
if (![System.IO.File]::Exists($manifest)) { return }

Remove-Item -Path $targetPath -Recurse

$lines = Get-Content -Path $manifest
$ver = ""
$compatible = ""
$dependency = ""

$newLines = @()

foreach($line in $lines) {
    if ($line.StartsWith("## Title: ", "OrdinalIgnoreCase")) {
        $Title = $line.Substring(10).Trim()
    }
    if ($line.StartsWith("## Version: ", "OrdinalIgnoreCase")) {
        $ver = $line.Substring(12).Trim().Replace(" ", "_")
    }
    if ($line.StartsWith("## ApiVersion: ", "OrdinalIgnoreCase")) {
        $compatible = $line.Substring(15).Trim().Split(" ")
    }
    if ($line.StartsWith("## DependsOn: ", "OrdinalIgnoreCase")) {
        $dependency = $line.Substring(14).Trim().Split(" ")
        for ($i = 0; $i -lt $dependency.Length; $i++) {
            $d = $dependency[$i]
            if ($d.Contains('>=')) {
                $dependency[$i] = $d.Substring(0, $d.IndexOf('>'))
            }
        }
    }
    if ($line.StartsWith("## ConsoleDependsOn: ", "OrdinalIgnoreCase")) {
        $dependency += $line.Substring(21).Trim().Split(" ")
        for ($i = 0; $i -lt $dependency.Length; $i++) {
            $d = $dependency[$i]
            if ($d.Contains('>=')) {
                $dependency[$i] = $d.Substring(0, $d.IndexOf('>'))
            }
        }
    }

    if ($line.StartsWith("PC\") -or $line.StartsWith("PC/") -or $line.StartsWith("Keyboard\") -or $line.StartsWith("Keyboard/")) { continue }
    if ($line -eq "Bindings.xml") { continue }

    $newLines += $line
}

$targetPath = [System.IO.Path]::Combine($PSScriptRoot,$targetName)
Remove-Item -Path $targetPath -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ($targetPath + "_v$ver.zip") -ErrorAction SilentlyContinue

Copy-Item -Recurse $Path $targetPath

if ($Title -ne "ESO Profiler") {
    Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "*")) -Recurse -Include "*.png","*.pdn" -Force
}
Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "*")) -Recurse -Include "Thumbs.db" -Force
Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "*.md")) -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "Bindings.xml")) -Force -ErrorAction SilentlyContinue
Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "$targetName.txt")) -Force -ErrorAction SilentlyContinue

Set-Content -Path ([System.IO.Path]::Combine($targetPath, "$targetName.addon")) -Value $newLines

Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "PC")) -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "Keyboard")) -Recurse -Force -ErrorAction SilentlyContinue

foreach($file in [System.IO.Directory]::GetFiles($targetPath, "Lib*.txt", "AllDirectories")) {
    if ([System.IO.Path]::GetFileName($file) -eq [System.IO.Path]::GetFileName($manifest)) { continue }
    $lib = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($file))
    if (($dependency | Where-Object { $_ -eq $lib }).Count -eq 0) {
        Write-Host "$lib not in DependOn. Continue?"
        Read-Host
    }
}

#$Filename = ($targetPath + "_v$ver.zip")
#&"C:\Program Files\7-Zip\7z.exe" a -tzip -r $Filename $targetPath

#Remove-Item -Path $targetPath -Recurse

$dependency

if (!$Upload) { return }

return

$Filename = Get-Item -Path $Filename

$Token = "5ff8072722ab0c814a37cae55a2fa225d0296a5fdd2cf55e98cc2a5172455337"

if (!$Filename.Exists) { return }
if (!$Filename.Name.EndsWith(".zip")) { return }
if ([string]::IsNullOrEmpty($Title)) { return }

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Web.Extensions

$baseUrl = "https://api.esoui.com/addons/"
$listUrl = $baseUrl + "list.json"
$detailsUrlTemplate = $baseUrl + "details/{0}.json"

if (!$Test) {
    # The real update
    $uploadUrl = $baseUrl + "update"
} else {
    # An update test for debugging script
    $uploadUrl = $baseUrl + "updatetest"
}

$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$json.MaxJsonLength = 41457280

$wc = New-Object system.Net.WebClient
$wc.Headers.Add("x-api-token", $Token)

# List addons you have access to
$list = $json.Deserialize($wc.DownloadString($listUrl), [System.Collections.ArrayList])

$details = $null
foreach($addon in $list) {

    if ($addon.title.Contains($Title)) {
        $details = $json.Deserialize($wc.DownloadString($addon.details), [System.Collections.ArrayList])
        break
    }
}
if ($details -eq $null) {
    Write-Host "Addon not found"
    return
}
if ($details.version -eq $ver) {
    Write-Host "Same Version"
    return
}

$boundary = "------------" + [DateTime]::Now.Ticks.ToString("x")
$enc = [System.Text.Encoding]::UTF8

function WriteText([System.IO.Stream]$s, [string]$text)
{
    $buffer = $enc.GetBytes($text)
    $s.Write($buffer, 0, $buffer.Length)
}

function WriteMultipartForm([System.IO.Stream]$s, $data, [System.IO.FileInfo] $fileName)
{
    if ($data -eq $null) { return }
    if ($data.id -eq $null) { return }

    # The first boundary
    [byte[]]$boundaryBytes = $enc.GetBytes("--$boundary`r`n")
    # The last boundary
    [byte[]]$trailer = $enc.GetBytes("`r`n--$boundary--`r`n")
    # the form data, properly formatted
    $formdataTemplate = "Content-Disposition: name=`"{0}`"`r`n`r`n{1}"
    # the form-data file upload, properly formatted
    $fileheaderTemplate = "Content-Type: application/zip`r`nContent-Disposition: name=`"{0}`"; filename=`"{1}`"`r`n`r`n"

    $hasLine = $false

    foreach ($row in $data.GetEnumerator())
    {
        # No newline on the first row
        if ($hasLine) { WriteText -s $s -text "`r`n" }

        # Write boundary
        $s.Write($boundaryBytes, 0, $boundaryBytes.Length)

        # Write row
        WriteText -s $s -text ([string]::Format($formdataTemplate, $row.Key, $row.Value))
        $hasLine = $true
    }

    WriteText -s $s -text "`r`n"

    $s.Write($boundaryBytes, 0, $boundaryBytes.Length)
    WriteText -s $s -text ([string]::Format($fileheaderTemplate, "updatefile", $fileName.Name))

    # Dump the file to the stream.
    $fs = $fileName.OpenRead()
    $fs.CopyTo($s)
    $fs.Close()

    $s.Write($trailer, 0, $trailer.Length)
}

$log = (git log -n 1 --pretty=format:"%B" "$Path")

try {
	$log = [String]::Join("`r`n", $log).Trim() + "`r`n`r`n" + $details.changelog.Trim()
}
catch {
	$log = $details.changelog.Trim()
}

$data = @{}
$data.id = $details.id
$data.version = $ver
$data.title = $details.title
$list = @()
if ($compatible -ccontains "101045") { $list+="10.3.5" }
if ($compatible -ccontains "101046") { $list+="11.0.0" }
if ($list.Count -lt 1) {
    Write-Host "API Version mismatch. Either manifest or script not up-to-date."
    return
}
$data.compatible = [String]::Join(",", $list) # comma delimited

#$data.description {"Type":"STR","Required":"No","Description":"Full description of your AddOn."}
$data.changelog = $log

#$data.archive     {"Type":"STR","Required":"No","Description":"Default\/Blank = Archive previous, Yes = Archive previous, No = Do not archive previous"}

$httpWebRequest = [System.Net.HttpWebRequest][System.Net.WebRequest]::Create($uploadUrl)
$httpWebRequest.Headers.Add("x-api-token", $Token)
$httpWebRequest.ContentType = "multipart/form-data; boundary=$boundary"
$httpWebRequest.Method = "POST"

$request = $httpWebRequest.GetRequestStream()
WriteMultipartForm -s $request -data $data -fileName $Filename
$request.Dispose()
[System.Net.HttpWebResponse]$response = $httpWebRequest.GetResponse()

$response.StatusCode
[int]$response.StatusCode

$sr = New-Object System.IO.StreamReader -ArgumentList @($response.GetResponseStream())
#$result = $json.Deserialize($sr.ReadToEnd(), [System.Collections.Hashtable])
$sr.Dispose()

if ($result -ne $null) {
    $result.testDiagnostics
}
