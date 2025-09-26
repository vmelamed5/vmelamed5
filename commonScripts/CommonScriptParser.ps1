param($infile)

if([String]::IsNullOrEmpty($infile)){
    Write-Host "FILE NAME (Ill append the .ps1): " -ForegroundColor Yellow -NoNewline
    $infile = Read-Host
}

$str = ""
$data = Get-Content "$PSScriptRoot\$infile.ps1"
foreach($line in $data){
    $str += $line
    $str += "\n"
}

Write-Host $str -ForegroundColor Cyan
$str | clip






