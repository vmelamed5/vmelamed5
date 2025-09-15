$str = ""
$AllFiles = Get-ChildItem -Path "$PSScriptRoot\commandData" -File
$counter = 0
$maxcount = $AllFiles.count
foreach($infile in $AllFiles.name){
    $counter += 1
    Write-Host "$counter / $maxcount) ANALYZING $infile" -ForegroundColor Yellow
    $data = Get-Content -Path "$PSScriptRoot\commandData\$infile"
    $str += $data + ",`n"
}
$str = $str.Substring(0, $str.Length - 1)

$str | clip
