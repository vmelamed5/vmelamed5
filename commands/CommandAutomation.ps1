﻿#COMMAND AUTOMATION
import-module vpasmodule -RequiredVersion 14.6.0 -Force
cd C:\Users\Vman\Desktop\VRepo\VpasModule\NewVpasWebsite\commands
<#
    Vadim Notes:
        - For new commands, add command in Template-Page sidebar section (lines 275ish - 600ish):
        - Fun fact - because im lazy, run this from the directory templatePage is in otherwise it will create in System32 (C:\Users\Vman\Desktop\VRepo\VpasModule\NewVpasWebsite\commands)
        - Dont forget to import the newest module version
#>

function LogFile{
    param($fileName, $str)

    write-output "$str" | Add-Content $fileName
}

$CommandMatrix = @{}

$commandcount = 0
$AllCommands = Get-Command -Module vpasmodule
$maxcommandcount = $AllCommands.Count
#$AllCommands = @{Name="Add-VPASAccount"} #<-- TESTING

$inputData = Get-Content -Path "Template-Page.html"

foreach($recCommand in $AllCommands.Name){
    $commandcount += 1
    $fileName = "$recCommand" + ".html"
    Write-Host "$commandcount / $maxcommandcount) BUILDING FILE: `t$fileName" -ForegroundColor Cyan
    Write-Output "<!-- MADE BY VADIM MELAMED -->" | Set-Content $fileName
    $CommandHelp = Get-help $recCommand -Full

    #PARSE ENVIRONMENT TYPES
    $EnvStatus = $CommandHelp.alertSet.alert.text
    $EnvStatusSplit = $EnvStatus -Split "`n"
    $SelfHostedStatus = $EnvStatusSplit[0] -replace "SelfHosted: ",""
    $PCloudStandardStatus = $EnvStatusSplit[1] -replace "PrivCloudStandard: ",""
    $SharedServicesStatus = $EnvStatusSplit[2] -replace "SharedServices: ",""

    #PARSE SYNOPSIS
    $CommandSynopsis = $CommandHelp.Synopsis
    $tempSplit = $CommandSynopsis -Split "`n"
    $CommandSynopsis = $tempSplit[0]

    #PARSE DESCRIPTION
    $CommandDescription = $CommandHelp.description.text
   
    #PARSE SYNTAX v2
    $CommandSyntaxArray = @()
    $tempSyntax = $CommandHelp.syntax | Out-String
    $tempSyntaxArr = $tempSyntax.Split("`r`n")
    $tempstr = ""
    foreach($temprec in $tempSyntaxArr){
        if($temprec.Length -ne 0){
            $temprec = $temprec -replace "<","&lt;"
            $temprec = $temprec -replace ">","&gt;"
            if($temprec -match "^$recCommand"){
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


    #PARSE PARAMETERS
    $AllParameters = $CommandHelp.parameters.parameter
    $CommandParameterArray = @()
    foreach($recParam in $AllParameters){
        $CommandParameterString = ""
        $ParamName = $recParam.name
        $ParamType = $recParam.parameterValue
        
        $tempval = $recParam | Out-String
        $tempval2 = $tempval -split "`r`n"
        $CheckSTR = $tempval2[1]
        $CheckSTR = $CheckSTR -replace "<","&lt;"
        $CheckSTR = $CheckSTR -replace ">","&gt;"
        $CommandParameterString += $CheckSTR + "<br>"

        $ParamDescription = $recParam.description.text
        $splittxt = $ParamDescription.split("`r`n")
        foreach($txt in $splittxt){
            $CommandParameterString += "$txt<br>"
        }
        $CommandParameterString += "<br>"

        $ParamRequired = $recParam.required
        $CommandParameterString += "Required: $ParamRequired<br>"

        $ParamPosition = $recParam.position
        $CommandParameterString += "Position: $ParamPosition<br>"

        $ParamDefaultValur = $recParam.defaultValue
        $CommandParameterString += "Default value: $ParamDefaultValur<br>"

        $ParamPipeline = $recParam.pipelineInput
        $CommandParameterString += "Accept pipeline input: $ParamPipeline<br>"
        
        #CONSISTENT
        $CommandParameterString += "Accept wildcard characters: false<br>"
        $CommandParameterArray += $CommandParameterString
    }
       
    $CommandParameterString = "&lt;CommonParameters&gt;<br>"
    $CommandParameterString += "This cmdlet supports the common parameters: Verbose, Debug<br>"
    $CommandParameterString += "ErrorAction, ErrorVariable, WarningAction, WarningVariable<br>"
    $CommandParameterString += "OutBuffer, PipelineVariable, and OutVariable. For more information, see<br>"
    $CommandParameterString += "about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216)<br>"
    $CommandParameterArray += $CommandParameterString

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
                if($txt2 -match "}"){
                    $curlycount -= 1
                }
                if($txt2 -match "\]"){
                    $curlycount -= 1
                }

                $i = 0
                while($i -lt ($curlycount * 8)){
                    $outputstr += "&nbsp;"
                    $i += 1
                }
                $outputstr += $txt2
                $outputstr += "<br>"
            
                if($txt2 -match "{"){
                    $curlycount += 1
                }
                if($txt2 -match "\["){
                    $curlycount += 1
                }
            }
        }
        $outputstr = $outputstr.Substring(0,($outputstr.Length-4))
        $CommandExampleArray += $outputstr
    }


    #PARSE OUTPUTS
    $AllOutputs = $CommandHelp.returnValues.returnValue.type.name
    $splittxt = $AllOutputs -split "---"
    $CommandOutputsArray = @()
    
    #SUCCES
    $ministr = ""
    $curlycount = 0
    $minitext = $splittxt[0].split("`r`n")
    foreach($txt2 in $minitext){
        if($txt2 -match "}"){
            $curlycount -= 1
        }
        if($txt2 -match "\]"){
            $curlycount -= 1
        }

        $i = 0
        while($i -lt ($curlycount * 8)){
            $ministr += "&nbsp;"
            $i += 1
        }
        $ministr += $txt2
        $ministr += "<br>"
            
        if($txt2 -match "{"){
            $curlycount += 1
        }
        if($txt2 -match "\["){
            $curlycount += 1
        }
    }
    $ministr = $ministr.Substring(0,($ministr.Length-4))
    $CommandOutputsArray += $ministr

    #FAILS
    $CommandOutputsArray += $splittxt[1]


    foreach($recline in $inputData){
        
        if($recline -match "ENTER_COMMAND_HERE"){
            #CAPTURE TAGS
            $recnewline = $recline -replace "ENTER_COMMAND_HERE",$recCommand
            LogFile -fileName $fileName -str $recnewline
        }
        elseif($recline -match "ENTER_SYNOPSIS_HERE"){
            #REPLACE TEXT WITH SYNOPSIS
            $recnewline = $recline -replace "ENTER_SYNOPSIS_HERE",$CommandSynopsis
            LogFile -fileName $fileName -str $recnewline
        }
        elseif($recline -match "ENTER_DESCRIPTION_HERE"){
            #REPLACE TEXT WITH DESCRIPTION
            $recnewline = $recline -replace "ENTER_DESCRIPTION_HERE",$CommandDescription
            LogFile -fileName $fileName -str $recnewline
        }
        elseif($recline -match "ENTER_SYNTAX_HERE"){
            #REPLACE TEXT WITH SYNTAX
            foreach($recEntry in $CommandSyntaxArray){
                $recnewline = $recline -replace "ENTER_SYNTAX_HERE",$recEntry
                LogFile -fileName $fileName -str $recnewline
            }
        }
        elseif($recline -match "ENTER_PARAMETERS_HERE"){
            #REPLACE TEXT WITH PARAMETERS
            foreach($recEntry in $CommandParameterArray){
                $recnewline = $recline -replace "ENTER_PARAMETERS_HERE",$recEntry
                LogFile -fileName $fileName -str $recnewline
            }
        }
        elseif($recline -match "ENTER_EXAMPLES_HERE"){
            #REPLACE TEXT WITH EXAMPLES
            foreach($recEntry in $CommandExampleArray){
                $recnewline = $recline -replace "ENTER_EXAMPLES_HERE",$recEntry
                LogFile -fileName $fileName -str $recnewline
            }
        }
        elseif($recline -match "ENTER_OUTPUTS_HERE"){
            #REPLACE TEXT WITH OUTPUTS
            foreach($recEntry in $CommandOutputsArray){
                $recnewline = $recline -replace "ENTER_OUTPUTS_HERE",$recEntry
                LogFile -fileName $fileName -str $recnewline
            }
        }
        elseif($recline -match "SelfHostedFlag"){
            $flagoutput = $SelfHostedStatus.ToLower()
            $recnewline = $recline -replace "SelfHostedFlag",$flagoutput
            LogFile -fileName $fileName -str $recnewline
        }
        elseif($recline -match "SharedServicesFlag"){
            $flagoutput = $SharedServicesStatus.ToLower()
            $recnewline = $recline -replace "SharedServicesFlag",$flagoutput
            LogFile -fileName $fileName -str $recnewline
        }
        elseif($recline -match "PCloudStandardFlag"){
            $flagoutput = $PCloudStandardStatus.ToLower()
            $recnewline = $recline -replace "PCloudStandardFlag",$flagoutput
            LogFile -fileName $fileName -str $recnewline
        }
        else{
            #JUST WRITE LINE BY LINE IF NO MATCH
            LogFile -fileName $fileName -str $recline
        }
    }
}