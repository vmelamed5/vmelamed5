#COMMAND AUTOMATION
import-module vpasmodule -RequiredVersion 14.2.1 -Force

<#
    Vadim Notes:
        - For new commands, add command in Template-Page sidebar section (lines 127ish - 315ish):
            ...
            <li class="nospacelist"><a href="./NEW-COMMAND.html" style="font-size: 14px; color: #f5f5f5;">&#8226; NEW-COMMAND</a></li>
            ...
        - For new commands, add to CSV file (CommandMatrix.csv)
            ...
            NEW-COMMAND,TRUE,FALSE,FALSE
            ...
        - Fun fact - because im lazy, run this from the directory templatePage is in otherwise it will create in System32
        - Dont forget to import the newest module version
#>

function LogFile{
    param($fileName, $str)

    write-output "$str" | Add-Content $fileName
}

$CommandMatrix = @{}
$inputCommandMatrix = Import-Csv -Path "CommandMatrix.csv"
foreach($rec in $inputCommandMatrix){
    $commandName = $rec.CommandName
    $SelfHostedStatus = $rec.SelfHosted
    $SharedServicesStatus = $rec.SharedServices
    $PCloudStandardStatus = $rec.PCloudStandard
    $CommandMatrix += @{
        $commandName = @{
            SelfHosted = $SelfHostedStatus
            SharedServices = $SharedServicesStatus
            PCloudStandard = $PCloudStandardStatus
        }
    }
}

$AllCommands = Get-Command -Module vpasmodule
#$AllCommands = @{Name="New-VPASToken"} #<-- TESTING

$inputData = Get-Content -Path "Template-Page.html"

foreach($recCommand in $AllCommands.Name){
    $fileName = "$recCommand" + ".html"
    Write-Host "BUILDING FILE: `t$fileName" -ForegroundColor Cyan
    Write-Output "<!-- MADE BY VADIM MELAMED -->" | Set-Content $fileName
    $CommandHelp = Get-help $recCommand -Full

    #PARSE SYNOPSIS
    $CommandSynopsis = $CommandHelp.Synopsis
    $tempSplit = $CommandSynopsis -Split "`n"
    $CommandSynopsis = $tempSplit[0]

    #PARSE DESCRIPTION
    $CommandDescription = $CommandHelp.description.text

    #PARSE SYNTAX
    $tempSyntax = $CommandHelp.syntax | Out-String
    $CommandSyntax = $tempSyntax -replace "`r`n",""
    $CommandSyntax = $CommandSyntax -replace "<","&lt;"
    $CommandSyntax = $CommandSyntax -replace ">","&gt;"

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

    #PARSE EXAMPLES
    $AllExamples = $CommandHelp.examples.example.code
    $CommandExamplesArray = @()
    foreach($txt in $AllExamples){
        $CommandExamplesArray += $txt
    }

    #PARSE OUTPUTS
    $AllOutputs = $CommandHelp.returnValues.returnValue.type.name
    $splittxt = $AllOutputs.split("`r`n")
    $CommandOutputsArray = @()
    foreach($txt in $splittxt){
        $CommandOutputsArray += $txt
    }



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
            $recnewline = $recline -replace "ENTER_SYNTAX_HERE",$CommandSyntax
            LogFile -fileName $fileName -str $recnewline
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
            foreach($recEntry in $CommandExamplesArray){
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
            $flagoutput = $CommandMatrix.$recCommand.SelfHosted.ToLower()
            $recnewline = $recline -replace "SelfHostedFlag",$flagoutput
            LogFile -fileName $fileName -str $recnewline
        }
        elseif($recline -match "SharedServicesFlag"){
            $flagoutput = $CommandMatrix.$recCommand.SharedServices.ToLower()
            $recnewline = $recline -replace "SharedServicesFlag",$flagoutput
            LogFile -fileName $fileName -str $recnewline
        }
        elseif($recline -match "PCloudStandardFlag"){
            $flagoutput = $CommandMatrix.$recCommand.PCloudStandard.ToLower()
            $recnewline = $recline -replace "PCloudStandardFlag",$flagoutput
            LogFile -fileName $fileName -str $recnewline
        }
        else{
            #JUST WRITE LINE BY LINE IF NO MATCH
            LogFile -fileName $fileName -str $recline
        }
    }
}