Param([string]$Title, [System.IO.FileInfo]$Filename)

$Token = "5ff8072722ab0c814a37cae55a2fa225d0296a5fdd2cf55e98cc2a5172455337"

if (!$Filename.Exists) { return }
if (!$Filename.Name.EndsWith(".zip")) { return }
if ([string]::IsNullOrEmpty($Title)) { return }

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Web.Extensions

$baseUrl = "https://api.esoui.com/addons/"
$listUrl = $baseUrl + "list.json"
$detailsUrlTemplate = $baseUrl + "details/{0}.json"
# The real update
#$uploadUrl = $baseUrl + "update"

# An update test for debugging script
$uploadUrl = $baseUrl + "updatetest"

$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$wc = New-Object system.Net.WebClient
$wc.Headers.Add("x-api-token", $Token)

# List addons you have access to
$list = $json.Deserialize($wc.DownloadString($listUrl), [System.Collections.ArrayList])

# Get details of the first (example)
$details = $json.Deserialize($wc.DownloadString($list[0].details), [System.Collections.ArrayList])
$details.filename

foreach($addon in $list) {

    if ($addon.title -eq $Title) {
        $details = $json.Deserialize($wc.DownloadString($addon.details), [System.Collections.ArrayList])
        break
    }
}
if ($details -eq $null) { return }

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

$data = @{}
$data.id = $details.id
$data.version = $details.version
$data.title = $details.title
$data.compatible = "2.7,2.6" # comma delimited

#$data.description {"Type":"STR","Required":"No","Description":"Full description of your AddOn."}
$data.changelog = $details.changelog

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
$result = $json.Deserialize($sr.ReadToEnd(), [System.Collections.Hashtable])
$sr.Dispose()

if ($result -ne $null) {
    $result.testDiagnostics
}
