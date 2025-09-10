#POPULATE commandJSONs

#REMINDERS!!!
#    Import the correct version of the module

import-module VpasModule -RequiredVersion 14.6.0 -Force

function xmlout{
    param($name,$tab,$str,$initial)

    $tempstr = ""
    while($tab -ne 0){
        $tempstr += "`t"
        $tab = $tab - 1
    }
    
    $tempstr += $str
    
    if($initial){
        Write-Output $tempstr | Set-Content "$PSScriptRoot/commandData/$name.html"
    }
    else{
        Write-Output $tempstr | Add-Content "$PSScriptRoot/commandData/$name.html"
    }
}
function Format-HashSnippet {
  param(
    [Parameter(Mandatory)] [string] $Text,
    [int] $IndentSize = 4
  )
  $sb = New-Object System.Text.StringBuilder
  $i = 0; $depth = 0
  $inStr = $false; $quote = ''

  while ($i -lt $Text.Length) {
    $ch = $Text[$i]

    if ($inStr) {
      [void]$sb.Append($ch)
      if ($ch -eq $quote) { $inStr = $false; $quote = '' }
      $i++; continue
    }

    if ($ch -eq '"' -or $ch -eq "'") {
      $inStr = $true; $quote = $ch
      [void]$sb.Append($ch); $i++; continue
    }

    # open hashtable: "@{"
    if ($ch -eq '@' -and $i+1 -lt $Text.Length -and $Text[$i+1] -eq '{') {
      [void]$sb.Append('@{')
      $depth++
      [void]$sb.Append("`n" + (' ' * ($depth * $IndentSize)))
      $i += 2; continue
    }

    # close brace: "}"
    if ($ch -eq '}') {
      $depth = [Math]::Max(0, $depth - 1)
      # trim any trailing spaces before we place the closing brace
      while ($sb.Length -gt 0 -and $sb[$sb.Length-1] -eq ' ') { $sb.Length-- }
      [void]$sb.Append("`n" + (' ' * ($depth * $IndentSize)) + '}')
      $i++; continue
    }

    # turn 2+ spaces (field separators) into newline + current indent
    if ($ch -eq ' ') {
      $j = $i
      while ($j -lt $Text.Length -and $Text[$j] -eq ' ') { $j++ }
      if ($j - $i -ge 2) {
        [void]$sb.Append("`n" + (' ' * ($depth * $IndentSize)))
        $i = $j; continue
      }
    }

    [void]$sb.Append($ch); $i++
  }

  # ensure newline between closing brace and trailing command/variable (e.g., $CreateAccountJSON)
  ($sb.ToString() -replace '}\s*(?=\$)', "}`n")
}
function Format-JsonChunks {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string] $Text,
    [switch] $AsHtmlLiteral,   # return escaped string for embedding (\" and \n)
    [switch] $AsArray          # return a single JSON array instead of multiple objects
  )

  # 1) Normalize encoding junk / BOM and unescape
  $s = $Text
  $s = $s -replace '^\uFEFF', ''         # real BOM
  $s = $s -replace '^\s*∩╗┐', ''         # mis-decoded BOM glyphs
  $s = [System.Text.RegularExpressions.Regex]::Unescape($s)  # \n, \t, \" -> real chars
  $s = $s -replace "`r?`n", "`n"         # normalize newlines

  # 2) Split into standalone JSON objects by tracking braces (ignore braces in strings)
  $chunks = @()
  $depth = 0; $start = $null
  $inStr = $false; $esc = $false
  for ($i = 0; $i -lt $s.Length; $i++) {
    $ch = $s[$i]
    if ($inStr) {
      if ($esc) { $esc = $false }
      elseif ($ch -eq '\') { $esc = $true }
      elseif ($ch -eq '"') { $inStr = $false }
      continue
    } else {
      if ($ch -eq '"') { $inStr = $true; continue }
      if ($ch -eq '{') {
        if ($depth -eq 0) { $start = $i }
        $depth++
      } elseif ($ch -eq '}') {
        $depth--
        if ($depth -eq 0 -and $start -ne $null) {
          $len = $i - $start + 1
          $chunks += $s.Substring($start, $len)
          $start = $null
        }
      }
    }
  }

  if ($chunks.Count -eq 0) { return "" }

  # 3) Parse and pretty print each chunk
  $prettyList = foreach ($c in $chunks) {
    try {
      $obj = $c | ConvertFrom-Json -ErrorAction Stop
      $json = $obj | ConvertTo-Json -Depth 64
    } catch {
      $json = $c  # fallback: raw text if parsing fails
    }
    if ($AsHtmlLiteral) {
      $json -replace '\\', '\\\\' `
           -replace '"',  '\"'   `
           -replace "`r?`n", '\n'
    } else {
      $json
    }
  }

  # 4) Return as multiple objects or a single array
  if ($AsArray) {
    if ($AsHtmlLiteral) {
      return "[`n" + ($prettyList -join ",`n") + "`n]"
    } else {
      $objs = foreach ($c in $chunks) { $c | ConvertFrom-Json }
      return ($objs | ConvertTo-Json -Depth 64)
    }
  } else {
    # separator between objects
    if ($AsHtmlLiteral) { $sep = '\n\n' } else { $sep = "`n`n" }
    return ($prettyList -join $sep)
  }
}
function Format-LooseChunks {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string] $Text,
    [int] $IndentSize = 4,
    [switch] $AsHtmlLiteral
  )

  # Normalize BOM / weird bytes / escapes
  $s = $Text
  $s = $s -replace '^\uFEFF', ''                       # BOM
  $s = $s -replace '[\u200B-\u200D\uFEFF]', ''         # zero-widths
  $s = $s -replace '^\s*∩╗┐', ''                       # mis-decoded BOM
  #$s = [System.Text.RegularExpressions.Regex]::Unescape($s)  # \n, \t, \" -> real chars
  $s = $s -replace "`r?`n", "`n"                       # normalize newlines

  $sb = New-Object System.Text.StringBuilder

  # Helpers that close over $sb (no $script: usage)
  $Append = {
    param([string]$t)
    [void]$sb.Append($t)
  }
  $Indent = {
    param([int]$n)
    [void]$sb.Append("`n" + (' ' * ($n * $IndentSize)))
  }

  $i = 0
  $depthBr = 0   # { }
  $depthPar = 0  # ( )
  $depthHash = 0 # @ { }
  $inStr = $false
  $quote = ''
  $escape = $false

  while ($i -lt $s.Length) {
    $ch = $s[$i]

    if ($inStr) {
      & $Append $ch
      if ($escape) { $escape = $false }
      elseif ($ch -eq '\') { $escape = $true }
      elseif ($ch -eq $quote) { $inStr = $false; $quote = '' }
      $i++; continue
    }

    # Enter string
    if ($ch -eq '"' -or $ch -eq "'") {
      $inStr = $true; $quote = $ch
      & $Append $ch; $i++; continue
    }

    # Start hashtable: "@{"
    if ($ch -eq '@' -and $i+1 -lt $s.Length -and $s[$i+1] -eq '{') {
      & $Append '@{'
      $depthHash++
      & $Indent ($depthBr + $depthPar + $depthHash)
      $i += 2
      # swallow whitespace immediately after "@{" to avoid blank line
      while ($i -lt $s.Length -and [char]::IsWhiteSpace($s[$i])) { $i++ }
      continue
    }

    # Open/close braces
    if ($ch -eq '{') {
      $depthBr++
      & $Append '{'
      & $Indent ($depthBr + $depthPar + $depthHash)
      $i++; continue
    }
    if ($ch -eq '}') {
      if ($depthHash -gt 0) { $depthHash-- }
      if ($depthBr -gt 0)   { $depthBr-- }
      # trim trailing spaces before closing token
      while ($sb.Length -gt 0 -and $sb[$sb.Length-1] -eq ' ') { $sb.Length-- }
      & $Indent ($depthBr + $depthPar + $depthHash)
      & $Append '}'
      $i++; continue
    }

    # Open/close parentheses
    if ($ch -eq '(') {
      $depthPar++
      & $Append '('
      & $Indent ($depthBr + $depthPar + $depthHash)
      $i++; continue
    }
    if ($ch -eq ')') {
      if ($depthPar -gt 0) { $depthPar-- }
      while ($sb.Length -gt 0 -and $sb[$sb.Length-1] -eq ' ') { $sb.Length-- }
      & $Indent ($depthBr + $depthPar + $depthHash)
      & $Append ')'
      $i++; continue
    }

    # Semicolon inside @{} => new property (ignore escaped \;)
    if ($ch -eq ';' -and $depthHash -gt 0) {
      if ($i -gt 0 -and $s[$i-1] -eq '\') {
        & $Append ';'; $i++; continue
      }
      & $Indent ($depthBr + $depthPar + $depthHash)
      $i++; continue
    }

    # Keep runs of dots ("..." etc.) on their own line
    if ($ch -eq '.' -and ($i+2 -lt $s.Length) -and $s[$i+1] -eq '.' -and $s[$i+2] -eq '.') {
      $j = $i; while ($j -lt $s.Length -and $s[$j] -eq '.') { $j++ }
      $dots = $s.Substring($i, $j - $i)
      & $Indent ($depthBr + $depthPar + $depthHash)
      & $Append $dots
      & $Indent ($depthBr + $depthPar + $depthHash)
      $i = $j; continue
    }

    # Convert large spaces (separators) to newline + indent
    if ($ch -eq ' ') {
      $j = $i
      while ($j -lt $s.Length -and $s[$j] -eq ' ') { $j++ }
      if ($j - $i -ge 2) {
        & $Indent ($depthBr + $depthPar + $depthHash)
        $i = $j; continue
      }
    }

    & $Append $ch
    $i++
  }

  # Ensure newline between ) or } and the next non-space token
  $out = $sb.ToString()
  $out = $out -replace '([}\)])\s+(?=\S)', "`$1`n"

  if ($AsHtmlLiteral) {
    $out = $out -replace '\\', '\\\\' -replace '"', '\"' -replace "`r?`n", '\n'
  }
  return $out
}

$commandcount = 0
#$AllCommands = Get-Command -Module vpasmodule
$AllCommands = @{Name="Remove-VPASAccount"} #<-- TESTING
$maxcommandcount = $AllCommands.Count
foreach($command in $AllCommands.Name){
    $commandcount += 1
    
    if($command -eq "Write-VPASOutput"){
        Write-host "($commandcount / $maxcommandcount) ANALYZING COMMAND: $command" -ForegroundColor Cyan
    }
    else{
        Write-host "($commandcount / $maxcommandcount) ANALYZING COMMAND: $command" -ForegroundColor Cyan
    
        $CommandHelp = Get-help $command -Full

        xmlout -name $command -tab 2 -str "{" -initial $true
        xmlout -name $command -tab 3 -str "id:`"$command`","
        xmlout -name $command -tab 3 -str "name:`"$command`","

        #GET CATEGORY
        $CommandCategoryTemp = $commandhelp.alertSet.alert.text
        $CommandCategoryTemp = $CommandCategoryTemp -split "\n"
        $CommandCategory = $CommandCategoryTemp[1] -replace "Tag: ",""
        xmlout -name $command -tab 3 -str "category:`"$CommandCategory`","

        #GET EXTRA TAGS
        $tagsstr = "tags:["
        $CommandExtraPropsTemp = $commandhelp.alertSet.alert.text
        $CommandExtraPropsTemp = $CommandExtraPropsTemp -split "\n"
        
            #COMMAND SINCE PROPERTY
            $commandsincetag = $CommandExtraPropsTemp[2]
            $commandsincetag = $commandsincetag -replace "Since","Introduced"
            $tagsstr += "`"$commandsincetag`","
        
            #COMMAND VERSION PROPERTY
            $commandversiontag = $CommandExtraPropsTemp[3]
            $tagsstr += "`"$commandversiontag`","

            #WHAT CYBERARK ENV PROPERTIES
            $shenv = $CommandExtraPropsTemp[4] -replace "SelfHosted: ",""
            $psenv = $CommandExtraPropsTemp[5] -replace "PrivCloudStandard: ",""
            $ssenv = $CommandExtraPropsTemp[6] -replace "SharedServices: ",""

            if($shenv -eq "TRUE"){ $tagsstr += "`"SelfHosted`"," }
            if($psenv -eq "TRUE"){ $tagsstr += "`"PrivCloudStandard`"," }
            if($ssenv -eq "TRUE"){ $tagsstr += "`"SharedServices`"," }

            $tagsstr = $tagsstr.Substring(0,$tagsstr.Length-1)
            $tagsstr += "],"
            xmlout -name $command -tab 3 -str $tagsstr



        #GET DESCRIPTION
        $CommandDescription = $CommandHelp.description.text
        xmlout -name $command -tab 3 -str "description:`"$CommandDescription`","

        #PARSE SYNTAX v2
        $CommandSyntaxArray = @()
        $tempSyntax = $CommandHelp.syntax | Out-String
        $tempSyntaxArr = $tempSyntax.Split("`r`n")
        $tempstr = ""
        foreach($temprec in $tempSyntaxArr){
            if($temprec.Length -ne 0){
                if($temprec -match "^$command"){
                    $tempstr += "@@@$temprec"
                }
                else{
                    $tempstr += $temprec
                }
            }
        }
        $tempstrbreak = $tempstr -split "@@@"
        foreach($temprec in $tempstrbreak){
            if($temprec.Length -ne 0){
                $CommandSyntaxArray += $temprec
            }
        }

        #PARSE EXAMPLES v2
        $CommandExampleArray = @()
        $AllExamples = $CommandHelp.examples.example
        foreach($ExampleRec in $AllExamples){
            $str1 = $ExampleRec.code | Out-String
            $str2 = $ExampleRec.remarks | Out-String
            $ministr = "$str1`n$str2"
            $curlycount = 0
            $outputstr = ""

            $ministrsplit = $ministr.Split("`r`n")
            foreach($txt2 in $ministrsplit){
                if($txt2.length -ne 0){
                    $outputstr += $txt2
                }
            }
            $CommandExampleArray += $outputstr
        }

        #PARSE OUTPUTS
        $AllOutputs = $CommandHelp.returnValues.returnValue.type.name
        $splittxt = $AllOutputs -split "---"
        $CommandOutputsArray = @()
    
        #SUCCES
        $successreturn = ""
        $ministr = ""
        $curlycount = 0
        $minitext = $splittxt[0].split("`r`n")
        foreach($txt2 in $minitext){
            $ministr += $txt2
        }
        $successreturn += $ministr
        $successreturn = $successreturn -replace "If successful:",""
        $successreturn = $successreturn -replace " if successful",""

        #FAILS
        $failreturn = $splittxt[1]
        $failreturn = $failreturn -replace " if failed",""
        $failreturn = $failreturn -replace "\n",""

        #PARAMETER SETS
        xmlout -name $command -tab 3 -str "parameterSets:["
        $syntaxcount = 0
        $maxsyntax = $CommandHelp.syntax.syntaxItem.Count
        foreach($commandsyntax in $CommandHelp.syntax.syntaxItem){
            $syntaxcount += 1
            xmlout -name $command -tab 4 -str "{"
            xmlout -name $command -tab 5 -str "name:`"ParameterSet$syntaxcount`","
            $curSyntax = $CommandSyntaxArray[$syntaxcount-1]
            xmlout -name $command -tab 5 -str "syntax:`"$curSyntax`","
            xmlout -name $command -tab 5 -str "parameters:["
            $paramcount = $commandsyntax.parameter.count
            $curparamcount = 0
            foreach($param in $CommandSyntax.parameter){
                $curparamcount += 1
                $paramname = $param.name
                $paramtype = $param.parameterValue
                $paramrequired = $param.required
                $paramdescription = $param.description.text
            
                $outputparamdescription = $paramdescription -replace "\n", " "


                $paramdescriptionSplit = $paramdescription -split "\n"
                if($paramdescriptionSplit[-1] -match "Possible values:"){
                    $tempstr = $paramdescriptionSplit[-1]
                    $tempstr = $tempstr -replace "Possible values: ",""
                    $tempstrsplit = $tempstr -split ", "
                    $paramvalidateset = "["
                    foreach($valset in $tempstrsplit){
                        $paramvalidateset += "`"$valset`","
                    }
                    $paramvalidateset = $paramvalidateset.Substring(0,$paramvalidateset.Length-1)
                    $paramvalidateset += "]"
                }
                else{
                    $paramvalidateset = "[]"
                }

                if($paramvalidateset -match '""'){
                    $paramvalidateset = $paramvalidateset -replace '""','"'
                }

                $outputparamdescription = $outputparamdescription -replace "`"","\`""
                if($curparamcount -eq $paramcount){
                    xmlout -name $command -tab 6 -str "{ name:`"$paramname`", type:`"$paramtype`", required:$paramrequired, description:`"$outputparamdescription`", validateSet:$paramvalidateset }"
                }
                else{
                    xmlout -name $command -tab 6 -str "{ name:`"$paramname`", type:`"$paramtype`", required:$paramrequired, description:`"$outputparamdescription`", validateSet:$paramvalidateset },"
                }
            }
            xmlout -name $command -tab 5 -str "],"
            xmlout -name $command -tab 5 -str "examples:["
        
            if($syntaxcount -ne $maxsyntax){
                $testExample1 = $CommandExampleArray[$syntaxcount-1]
                if(![String]::IsNullOrEmpty($testExample1)){
                    $testExample1 = $testExample1 -replace "`"","\`""
                    xmlout -name $command -tab 6 -str "{ caption:`"ParameterSet$syntaxcount`", code:`"$testExample1`" }"
                }
            }
            else{
                $curleft = $CommandExampleArray.count - $syntaxcount + 1
                $fakemaxsyntax = $syntaxcount + $curleft
                while($syntaxcount -ne $fakemaxsyntax){
                    $testExample1 = $CommandExampleArray[$syntaxcount-1]
                    if(![String]::IsNullOrEmpty($testExample1)){
                        $testExample1 = Format-HashSnippet $testExample1 4
                        $testExample1 = $testExample1 -replace '\\', '\\\\'
                        $testExample1 = $testExample1 -replace '"',  '\"'   
                        $testExample1 = $testExample1 -replace "`r?`n", '\n'


                        if(($syntaxcount + 1) -eq $fakemaxsyntax){
                            xmlout -name $command -tab 6 -str "{ caption:`"ParameterSet$maxsyntax`", code:`"$testExample1`" }"
                        }
                        else{
                            xmlout -name $command -tab 6 -str "{ caption:`"ParameterSet$maxsyntax`", code:`"$testExample1`" },"
                        }
                    }
                    $syntaxcount += 1
                }
            }

            xmlout -name $command -tab 5 -str "]"

            if($syntaxcount -eq $maxsyntax){
                xmlout -name $command -tab 4 -str "}"
            }
            else{
                xmlout -name $command -tab 4 -str "},"
            }
        }
    
        #Write-Host $successreturn -ForegroundColor Green
        #$successreturn | clip

        if($successreturn -ne "`$true"){
            $specialcommands = @(
                "New-VPASPSMSession",
                "Watch-VPASActivePSMSession",
                "Add-VPASIdentityRole",
                "Get-VPASAccountPrivateSSHKey",
                "Get-VPASPasswordValue",
                "Invoke-VPASAccountPasswordAction",
                "Invoke-VPASMetricsAccounts",
                "Invoke-VPASMetricsCPM",
                "Invoke-VPASMetricsPlatforms",
                "Invoke-VPASMetricsProviders",
                "Invoke-VPASMetricsPSM",
                "Invoke-VPASQuery",
                "New-VPASIdentityGenerateUserPassword"
            )
            if($specialcommands.Contains($command)){        
                $successreturn = Format-LooseChunks $successreturn -AsHtmlLiteral
            }
            else{
                $successreturn = Format-JsonChunks $successreturn -AsHtmlLiteral
            }
        }

        #Write-Host $successreturn -ForegroundColor yellow

        xmlout -name $command -tab 3 -str "],"
        xmlout -name $command -tab 3 -str "output:["
        xmlout -name $command -tab 4 -str "{ caption: `"Success`", code:`"$successreturn`" },"
        xmlout -name $command -tab 4 -str "{ caption: `"Fail`", code:`"$failreturn`" }"
        xmlout -name $command -tab 3 -str "]" 
        xmlout -name $command -tab 2 -str "}"
    }
}



