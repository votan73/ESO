param($Path="", [switch]$Upload=$false, [switch]$Test=$false, [switch]$Bundle=$false)

$Token = "5ff8072722ab0c814a37cae55a2fa225d0296a5fdd2cf55e98cc2a5172455337"

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Web.Extensions

$blackList = @{}
$blackList["LibGPS2"] = $true
$blackList["CDGBankStack"] = $true
$blackList["CustomMapPinsImagePack"] = $true
$blackList["DeconstructionFilter"] = $true
$blackList["emotes"] = $true
$blackList["DungeonQueue4Stickerbook"] = $true
#$blackList["EnchantMaker"] = $true
$blackList["EnchantedQuality"] = $true
$blackList["ESOProfiler"] = $true
#$blackList["HarvensCustomMapPins"] = $true
$blackList["HarvensPotionsAlert"] = $true
$blackList["HarvensTraitAndStyle"] = $true
$blackList["HomesteadOCD"] = $true
$blackList["iChat"] = $true
$blackList["InfoBar"] = $true
$blackList["libCommonInventoryFilters"] = $true
$blackList["LibAddonMenu-2.0"] = $true
#$blackList["LibGPS"] = $true
$blackList["LibRuneBox"] = $true
$blackList["LibHarvensAddonSettings"] = $true
$blackList["LibMapPing"] = $true
$blackList["LibStub"] = $true
$blackList["LoadingScreenDetector"] = $true
$blackList["LootWall"] = $true
$blackList["merCharacterSheet"] = $true
$blackList["NoHelmet"] = $true
$blackList["SetManager"] = $true
$blackList["SousChef"] = $true
$blackList["Troublemaker"] = $true
$blackList["UnitFramesRebirth"] = $true
$blackList["VotansContactList"] = $true
$blackList["VotansCollectSet"] = $true
$blackList["VotansDolmenTimer"] = $true
#$blackList["VotansFisherman"] = $true
$blackList["VotansHarvester"] = $true
$blackList["VotansMoonClock"] = $true
$blackList["VotansInventoryFilter"] = $true
$blackList["VotansMotifsHunter"] = $true
$blackList["VotansTakeOne"] = $true
$blackList["VotansTrophyCabinet"] = $true
$blackList["VotansUIFixes"] = $true
$blackList["WandasThievesBagsCounts"] = $true
$blackList["VotansImprovedMapMenu"] = $true
#$blackList["LibAlchemyStation"] = $true
#$blackList["LibEnchantingStation"] = $true
$blackList["LibTextFilter"] = $true
$blackList["LibMsgWin-1.0"] = $true
$blackList["RareFishTracker"] = $true
$blackList["SetSwap"] = $true
$blackList["VotansWorldClocks"] = $true
$blackList["VotansNicerUnboundKeys"] = $true
$blackList["VotansAssistentFeatures"] = $true
$blackList["VotansSelectDifficulty"] = $true
$blackList["VotansWorldChampBuff"] = $true

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
$addonList = $json.Deserialize($wc.DownloadString($listUrl), [System.Collections.ArrayList])

foreach($Path in [System.IO.Directory]::GetDirectories($Path)){
    if ($Path.Length -eq 0){ continue }
    if ($Path.Length -eq 0){ continue }
    if (![System.IO.Directory]::Exists($Path)) { continue }

    $targetName = [System.IO.Path]::GetFileName($Path)
    if ($targetName.Length -eq 0){ continue }
    if ($blackList[$targetName]) {
        Write-Host -ForegroundColor Yellow "Skipped blacklisted $targetName"
        continue
    }
    $manifest = [System.IO.Path]::Combine($Path,$targetName+".addon")
    if (![System.IO.File]::Exists($manifest)) {
        $manifest = [System.IO.Path]::Combine($Path,$targetName+".txt")
    }
    if (![System.IO.File]::Exists($manifest)) { continue }

    $lines = Get-Content -Path $manifest
    $ver = ""
    $compatible = ""
    $dependency = ""
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
        if ($Bundle -and $line.StartsWith("## DependsOn: ", "OrdinalIgnoreCase")) {
            $dependency = $line.Substring(14).Trim().Split(" ")
	        for ($i = 0; $i -lt $dependency.Length; $i++) {
	            $d = $dependency[$i]
	            if ($d.Contains('>=')) {
	                $dependency[$i] = $d.Substring(0, $d.IndexOf('>'))
            	}
	        }
        }
    }

    $targetPath = [System.IO.Path]::Combine($PSScriptRoot,$targetName)
    Remove-Item -Path $targetPath -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path ($targetPath + "_v$ver.zip") -ErrorAction SilentlyContinue

    Copy-Item -Recurse $Path $targetPath

	if ($Title -ne "ESO Profiler") {
	    Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "*")) -Recurse -Include "*.png","*.pdn"
	}
    Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "*")) -Recurse -Include "*.db"
	
	$libTargetPath = [System.IO.Path]::Combine($targetPath, "libs")
	if (![System.IO.Directory]::Exists($libTargetPath)) { $libTargetPath = $targetPath }
	
	foreach($lib in $dependency | Where-Object { $_ -like "Lib*" }) {
	    $found = $false
	    foreach($file in [System.IO.Directory]::GetFiles($targetPath, "$lib.txt", "AllDirectories")) {
	        if ([System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($file)) -eq $lib) {
	            $found = $true
	            break
	        }
	    }
	    if (!$found) {
	        $isLibStubIncluded = [System.IO.Directory]::GetFiles($targetPath, "LibStub.txt", "AllDirectories").Count -gt 0
	        $libSourcePath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($Path), $lib)
	        if (![System.IO.Directory]::Exists($libSourcePath)) {
	            $libSourcePath = [System.IO.Path]::GetDirectoryName(([System.IO.Directory]::GetFiles([System.IO.Path]::GetDirectoryName($Path), "$lib.txt", "AllDirectories"))[0])
	        }
	        $bundlePath = [System.IO.Path]::Combine($libTargetPath, $lib)
	        if ([System.IO.Directory]::Exists($libSourcePath)) {
	            $result = svn export $libSourcePath $bundlePath 
	            if ($result -eq $null) {
	                Copy-Item -Path $libSourcePath -Destination $bundlePath -Recurse
	            }
	            $found = $true
	        }
	        #if ($isLibStubIncluded) {
	        #    foreach($libSourcePath in [System.IO.Directory]::GetDirectories($bundlePath, "LibStub", "AllDirectories")) {
	        #        [System.IO.Directory]::Delete($libSourcePath, $true)
	        #    }
	        #}
	    }
	    if (!$found) {
	        Write-Host "$lib not found. Continue?"
	        Read-Host
	    }
	}
    Remove-Item -Path ([System.IO.Path]::Combine($targetPath, "*")) -Recurse -Include "*.png","*.pdn"

	#foreach($libSourcePath in ([System.IO.Directory]::GetDirectories($targetPath, "*", "AllDirectories")|Sort-Object -Descending)) {
	#    try {
	#    $result = [System.IO.Directory]::Delete($libSourcePath)
	#    } catch {}
	#}

    $Filename = ($targetPath + "_v$ver.zip")
    &"C:\Program Files\7-Zip\7z.exe" a -tzip -r $Filename $targetPath 1>$null

    Remove-Item -Path $targetPath -Recurse -Force



    $Filename = Get-Item -Path $Filename

	if (!$Filename.Exists) { return }
	if (!$Filename.Name.EndsWith(".zip")) { return }
	if ([string]::IsNullOrEmpty($Title)) { return }

    ##$wc.Headers.Add("x-api-token", $Token)

    $details = $null
    foreach($addon in $addonList) {

        if ($addon.title -like "*$Title*") {
            $details = $json.Deserialize($wc.DownloadString($addon.details), [System.Collections.ArrayList])
            break
        }
    }
    if ($details -eq $null) {
        Write-Host -ForegroundColor Red "Addon not found $targetName"
        continue
    }
    if ($details.version -eq $ver) {
        Write-Host -ForegroundColor Green "Same Version $targetName"
        continue
    }
    if (!$Upload) {
        Write-Host -ForegroundColor Cyan "<= Would upload $targetName =>"
        continue
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
    if ($list.Length -lt 2) {
        Write-Host -ForegroundColor Red "Manifest or script not up-to-date. " + $data.title
        continue
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
    $sr.ReadToEnd()
    #$result = $json.Deserialize($sr.ReadToEnd(), [System.Collections.Hashtable])
    $sr.Dispose()

    sleep (1*60+57)
}