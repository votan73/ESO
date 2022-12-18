param($Path="", [switch]$Upload=$false, [switch]$Test=$false)

$Token = "5ff8072722ab0c814a37cae55a2fa225d0296a5fdd2cf55e98cc2a5172455337"

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Web.Extensions

$blackList = @{}
$blackList["LibGPS2"] = $true
$blackList["CDGBankStack"] = $true
$blackList["CustomMapPinsImagePack"] = $true
$blackList["DeconstructionFilter"] = $true
$blackList["emotes"] = $true
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
$blackList["LibGPS"] = $true
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
$blackList["VotansDolmenTimer"] = $true
$blackList["VotansHarvester"] = $true
$blackList["VotansMoonClock"] = $true
$blackList["VotansMotifsHunter"] = $true
$blackList["VotansTakeOne"] = $true
$blackList["VotansTrophyCabinet"] = $true
$blackList["VotansUIFixes"] = $true
$blackList["WandasThievesBagsCounts"] = $true
$blackList["VotansImprovedMapMenu"] = $true
$blackList["LibAlchemyStation"] = $true
#$blackList["LibEnchantingStation"] = $true
$blackList["LibTextFilter"] = $true
$blackList["LibMsgWin-1.0"] = $true
$blackList["SetSwap"] = $true
$blackList["VotansWorldClocks"] = $true

$depSource = @{}
$depSource["HarvensCustomMapPins"] = @("Harven's Custom Map Pins (Markers)", "https://www.esoui.com/downloads/info357-HarvensCustomMapPinsMarkers.html")
$depSource["libAddonKeybinds"] = @("libAddonKeybinds", "https://www.esoui.com/downloads/info1253-libAddonKeybinds.html")
$depSource["LibAddonMenu-2.0"] = @("LibAddonMenu", "https://www.esoui.com/downloads/info7-LibAddonMenu.html")
$depSource["LibAlchemyStation"]= @("LibAlchemyStation", "https://www.esoui.com/downloads/info2628-LibAlchemyStation.html")
$depSource["LibAsync"] = @("LibAsync", "https://www.esoui.com/downloads/info2125-LibAsync.html")
$depSource["libCommonInventoryFilters"] = @("libCommonInventoryFilters", "https://www.esoui.com/downloads/info2271-libCommonInventoryFilters.html")
$depSource["LibCustomMenu"] = @("LibCustomMenu", "https://www.esoui.com/downloads/info1146-LibCustomMenu.html")
$depSource["LibDebugLogger"] = @("LibDebugLogger", "https://www.esoui.com/downloads/info2275-LibDebugLogger.html")
$depSource["LibEnchantingStation"]= @("LibEnchantingStation", "https://www.esoui.com/downloads/info2437-LibEnchantingStation.html")
$depSource["LibGPS"] = @("LibGPS", "https://www.esoui.com/downloads/info601-LibGPS.html")
$depSource["LibHarvensAddonSettings"] = @("LibHarvensAddonSettings", "https://www.esoui.com/downloads/info584-LibHarvensAddonsSettings.html")
$depSource["LibMainMenu-2.0"] = @("LibMainMenu-2.0", "https://www.esoui.com/downloads/info2118-LibMainMenu-2.0.html")
$depSource["LibMapPing"] = @("LibMapPing", "https://www.esoui.com/downloads/info1302-LibMapPing.html")
$depSource["LibTextFilter"] = @("LibTextFilter", "https://www.esoui.com/downloads/info1311-LibTextFilter.html")
$depSource["LibWorldMapInfoTab"]= @("LibWorldMapInfoTab", "https://www.esoui.com/downloads/info1568-LibWorldMapInfoTab.html")
$depSource["LibMapPins-1.0"]= @("LibMapPins-1.0", "https://www.esoui.com/downloads/info563-LibMapPins.html")
$depSource["LibChatMessage"]= @("LibChatMessage", "https://www.esoui.com/downloads/info2382-LibChatMessage.html")


$descriptionTitle = '[SIZE="3"][COLOR="DarkOrange"]Description[/COLOR][/SIZE]'
$dependencyTitle = '[SIZE="3"][COLOR="DarkOrange"]Dependencies[/COLOR][/SIZE]' 

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
$json.MaxJsonLength = 31457280

$wc = New-Object system.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::UTF8
$wc.Headers.Add("x-api-token", $Token)

# List addons you have access to
$addonList = $json.Deserialize($wc.DownloadString($listUrl), [System.Collections.ArrayList])

foreach($Path in [System.IO.Directory]::GetDirectories("Z:\release")){
    if ($Path.Length -eq 0){ continue }
    if ($Path.Length -eq 0){ continue }
    if (![System.IO.Directory]::Exists($Path)) { continue }

    $targetName = [System.IO.Path]::GetFileName($Path)
    if ($targetName.Length -eq 0){ continue }
    if ($blackList[$targetName]) {
        Write-Host -ForegroundColor Yellow "Skipped blacklisted $targetName"
        continue
    }
    $manifest = [System.IO.Path]::Combine($Path,$targetName+".txt")
    if (![System.IO.File]::Exists($manifest)) { continue }

    Write-Host "------------"
    Write-Host $targetName

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
        if ($line.StartsWith("## DependsOn: ", "OrdinalIgnoreCase")) {
            $dependency = $line.Substring(14).Trim().Split(" ")
	        for ($i = 0; $i -lt $dependency.Length; $i++) {
	            $d = $dependency[$i]
	            if ($d.Contains('>=')) {
	                $dependency[$i] = $d.Substring(0, $d.IndexOf('>'))
            	}
	        }
        }
    }

    ##if (!$Upload) { continue }

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
        Write-Host -ForegroundColor Red ("Addon not found " + $Title)
        continue
    }
    if ($details.version -ne $ver) {
        Write-Host -ForegroundColor Green "Not Same Version"
        continue
    }

    $boundary = "------------" + [DateTime]::Now.Ticks.ToString("x")
    $enc = [System.Text.Encoding]::UTF8

    function WriteText([System.IO.Stream]$s, [string]$text)
    {
        $buffer = $enc.GetBytes($text)
        $s.Write($buffer, 0, $buffer.Length)
    }

    function WriteMultipartForm([System.IO.Stream]$s, $data)
    {
        if ($data -eq $null) { return }
        if ($data.id -eq $null) { return }

        # The first boundary
        [byte[]]$boundaryBytes = $enc.GetBytes("--$boundary`r`n")
        # The last boundary
        [byte[]]$trailer = $enc.GetBytes("`r`n--$boundary--`r`n")
        # the form data, properly formatted
        $formdataTemplate = "Content-Disposition: name=`"{0}`"`r`n`r`n{1}"

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

        $s.Write($trailer, 0, $trailer.Length)
    }

    $data = @{}
    $data.id = $details.id
    $data.version = $ver
    $data.title = $details.title
    $list = @()
	#if ($compatible -ccontains "100030") { $list+="5.3.4" }
	#if ($compatible -ccontains "100031") { $list+="6.0.5" }
    #$data.compatible = [String]::Join(",", $list) # comma delimited
    $data.compatible = [String]::Join(",",  $details.compatibility)

    $description = $details.description
    if ($description -eq $null) { $description = "" }
    $description = $description.Trim()
    if (!$description.Contains($descriptionTitle) -and !$description.StartsWith("[SIZE=", "OrdinalIgnoreCase")) {
        $description = $descriptionTitle + "`r`n" + $description
    }
    $hasDependencySection = $description.Contains($dependencyTitle)
    if ($hasDependencySection) {
        $index = $description.IndexOf($dependencyTitle)
        $index2 = $description.IndexOf("[/LIST]", $index)
        $hasDependencySection = $index2 -gt $index
        if ($hasDependencySection) {
            $description = $description.Substring(0, $index) + $description.Substring($index2 + 7).Trim()
        }
    }
    if ($dependency.Length -gt 0) {
        $temp = $dependencyTitle + "`r`n"
        $temp += "[LIST]`r`n"
        $list = New-Object System.Collections.Generic.List[string]
        $list.AddRange([string[]]$dependency.Split(" "))
        $list.Sort()
        foreach($dep in $list) {
            $part = $dep.Split(">=")[0]
            try{
            $temp += "[*]" + '[URL="' + $depSource[$part][1] + '"]' + $depSource[$part][0] + "[/URL]`r`n"
            }
            catch {
            ($dep + " not found")
            break
            }
        }
        $temp += "[/LIST]`r`n"
        $description = $temp + $description
    }

    if ($details.description -eq $description) {
        continue
    }

    $data.description = $description

    if (!$Upload) { continue }
    Write-Host -ForegroundColor Green ("uploading " + $Title)

    $httpWebRequest = [System.Net.HttpWebRequest][System.Net.WebRequest]::Create($uploadUrl)
    $httpWebRequest.Headers.Add("x-api-token", $Token)
    $httpWebRequest.ContentType = "multipart/form-data; boundary=$boundary"
    $httpWebRequest.Method = "POST"

    $request = $httpWebRequest.GetRequestStream()
    WriteMultipartForm -s $request -data $data
    $request.Dispose()
    [System.Net.HttpWebResponse]$response = $httpWebRequest.GetResponse()

    $response.StatusCode
    [int]$response.StatusCode

    $sr = New-Object System.IO.StreamReader -ArgumentList @($response.GetResponseStream())
    $result = $sr.ReadToEnd()
    $index = $result.LastIndexOf('{"STATUS"')
    if ($index -gt 0) {
        $status = $json.Deserialize($result.Substring($index), [System.Collections.Hashtable])
        $result = $json.Deserialize($result.Substring(0, $index), [System.Collections.ArrayList])
    }
    $sr.Dispose()

    if ($result -ne $null) {
        $result.testDiagnostics
    }
}