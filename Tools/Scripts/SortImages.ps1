$root = "C:\Users\Votan.Defiant\Data\Documents\Visual Studio 2012\Projects\ElderScrollsResources\ElderScrollsResources\bin\Debug\live"
$files = [System.IO.Directory]::GetFiles("$root", "*.dds", "AllDirectories")
$sizes = New-Object 'System.Collections.Generic.SortedDictionary`2[int, string]'
$sizes[2048] = "$root\Images\2k"
$sizes[4096] = "$root\Images\4k"
$sizes[6144] = "$root\Images\6k"
$sizes[8192] = "$root\Images\8k"
$sizes[12288] = "$root\Images\12k"
$sizes[16384] = "$root\Images\16k"
$sizes[24576] = "$root\Images\24k"
$sizes[32768] = "$root\Images\32k"
$sizes[49152] = "$root\Images\48k"
$sizes[65536] = "$root\Images\64k"
$sizes[98304] = "$root\Images\96k"
$sizes[131072] = "$root\Images\128k"
$sizes[196608] = "$root\Images\192k"
$sizes[262144] = "$root\Images\256k"
$sizes[393216] = "$root\Images\384k"
$sizes[524288] = "$root\Images\large"

$defaultSize = "$root\Images\huge"

foreach($size in $sizes.Values) {
    [System.IO.Directory]::CreateDirectory($size)
}
[System.IO.Directory]::CreateDirectory($defaultSize)

foreach($file in $files) {
    $target = $defaultSize
    $info = [System.IO.FileInfo]$file
    foreach($entry in $sizes.GetEnumerator()) {
        if ($info.Length -le $entry.Key) {
            $target = $entry.Value
            break
        }
    }
    $path = [System.IO.Path]::Combine($target, $info.Name)
    if ($info.FullName -ne $path) { $info.MoveTo($path) }
}
