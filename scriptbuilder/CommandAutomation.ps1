#COMMAND AUTOMATION
<#
    - Should automate from the Template-Page.html in the same directory as this script!!!
    - dont forget to import the latest and greatest version
#>

import-module vpasmodule -RequiredVersion 14.6.0 -Force
cd C:\Users\Vman\Desktop\VRepo\VpasModule\NewVpasWebsite\scriptbuilder

$global:test = $false

function LogFile{
    param($fileName, $str)

    write-output "$str" | Add-Content $fileName
}
function GenerateStr{
    param($str,$tabs)

    $count = 0
    $output = ""
    while($count -lt $tabs){
        $output += "`t"
        $count += 1
    }
    $output += $str + "`n"
    return $output
}
function GenerateStrNoSpace{
    param($str,$tabs)

    $count = 0
    $output = ""
    while($count -lt $tabs){
        $output += "`t"
        $count += 1
    }
    $output += $str
    return $output
}
function GetAllRequiredProps{
    param($fileName)
    
    if($global:test){
        $AllCommands = @{
            name = @("Get-VPASEPVUserDetails","Get-VPASAccountDetails")
        }
    }
    else{
        $AllCommands = Get-Command -Module vpasmodule
    }

    foreach($rec in $AllCommands.name){
        $str = ""
        if($rec -ne "New-VPASToken" -and $rec -ne "Write-VPASOutput"){
            $ParamCounter = 0
            $indexcounter = 0
            $ParamSets = ((Get-Command $rec)).ParameterSets
            foreach($pset in $ParamSets){
                
                $SetName = $pset.Name
                if($SetName -eq "InputParameters"){
                    #DO NOTHING
                }
                else{
                    $indexcounter += 1
                    $AllRequiredParams = $pset.parameters | Where-Object isMandatory -eq 1
                    $str += GenerateStr -str "<div id=`"div$rec-ParameterSet$indexcounter`" class=`"divCommands`" style=`"text-align: left; font-size: 12px; margin-left: 1%; display: none; width: 700px;`">" -tabs 17
                    $str += GenerateStr -str "<div class=`"col-4 col-12-small`">" -tabs 17

                    $ParameterSetCount = (((Get-Command $rec)).ParameterSets.count) - 1
                    $tempindex = 0
                    while($tempindex -lt $ParameterSetCount){
                        $temptempindex = $tempindex + 1
                        if($temptempindex -eq $indexcounter){    
                            $str += GenerateStr -str "<input type=`"radio`" id=`"$rec-ParameterSet$temptempindex`" name=`"$rec-ParameterSet$indexcounter`" value=`"set$temptempindex`" onclick=`"toggleSetMode('$rec', '$temptempindex')`" checked><label for=`"$rec-ParameterSet$temptempindex`">Set$temptempindex</label>" -tabs 18
                        }
                        else{
                            $str += GenerateStr -str "<input type=`"radio`" id=`"$rec-ParameterSet$temptempindex`" name=`"$rec-ParameterSet$indexcounter`" value=`"set$temptempindex`" onclick=`"toggleSetMode('$rec', '$temptempindex')`"><label for=`"$rec-ParameterSet$temptempindex`">Set$temptempindex</label>" -tabs 18
                        }
                        $tempindex += 1
                    }

                    $str += GenerateStr -str "</div>" -tabs 17
                    $str += GenerateStr -str "<div class=`"metrics-container-reverse`" style=`"width: 100%; padding-top: 0px;`">" -tabs 18
                    $str += GenerateStr -str "<div class=`"metric-reverse`"><p style=`"text-align: left; font-size: 14px; margin-bottom: 5px;`"><b>$rec : Required Parameters (Set$indexcounter)</b></p></div>" -tabs 19
                    $str += GenerateStr -str "<div class=`"metrics-container`" style=`"width: 100%;`">" -tabs 19
                    $str += GenerateStr -str "<form>" -tabs 20

                    if($AllRequiredParams.count -eq 0){
                        $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                        $str += GenerateStr -str "<label id=`"$rec-RequiredLabel-NA-ParameterSet$indexcounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px; display: none;`" for=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`">:</label>" -tabs 22
                        $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`"><input readonly style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`" name=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`" placeholder=`"NO REQUIRED PARAMETERS`"></label><br><span class=`"requiredtooltiptext`">This command has NO required parameters</span></div>" -tabs 22
                        $str += GenerateStr -str "</div>" -tabs 21

                    }
                    elseif($AllRequiredParams.count -eq 1 -and $AllRequiredParams.name -eq "InputParameters"){
                        $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                        $str += GenerateStr -str "<label id=`"$rec-RequiredLabel-NA-ParameterSet$indexcounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px; display: none;`" for=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`">:</label>" -tabs 22
                        $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`"><input readonly style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`" name=`"$rec-RequiredParam-NA-ParameterSet$indexcounter`" placeholder=`"NO REQUIRED PARAMETERS`"></label><br><span class=`"requiredtooltiptext`">This command has NO required parameters</span></div>" -tabs 22
                        $str += GenerateStr -str "</div>" -tabs 21
                    }
                    else{
                        foreach($RequiredParam in $AllRequiredParams){
                            $param = $RequiredParam.Name
                    
                            if($param -eq "InputParameters"){
                                #DO NOTHING
                            }
                            else{
                                $paramType = $RequiredParam.ParameterType.Name
                                $paramValidValues = $RequiredParam.Attributes.validvalues
                                $AllInfo = Get-Help -Name $rec
                                $paramexplanation = "BLANK"

                                foreach($tempparam in $AllInfo.parameters.parameter){
                                    $tempparamname = $tempparam.name
                                    $tempparamdescription = $tempparam.description.text

                                    if($tempparamname -eq $param){
                                        $paramexplanation = $tempparamdescription.replace("`n"," - ")
                                    }
                                }

                                if($paramType -eq "String"){
                                    if($paramValidValues.count -eq 0){
                                        $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                        $str += GenerateStr -str "<label id=`"$rec-RequiredLabel-$param-ParameterSet$indexcounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`">$param`:</label>" -tabs 22
                                        $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`"><input style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`" name=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`" placeholder=`"Enter $param Value Here...`"></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>" -tabs 22
                                        $str += GenerateStr -str "</div>" -tabs 21
                                    }
                                    else{
                                        #MAKE A DROP DOWN
                                        $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                        $str += GenerateStr -str "<label id=`"$rec-RequiredLabel-$param-ParameterSet$indexcounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`">$param`:</label>" -tabs 22
                            
                                        $tempstr = "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`"><select style=`"font-size: 12px; background-color: #4C5C96; background-size: 2rem;`" id=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`" name=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`">"
                                        foreach($validval in $paramValidValues){
                                            $tempstr += "<option value=`"$validval`">$validval</option>"

                                        }
                                        $tempstr += "</select></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>"
                                        $str += GenerateStr -str $tempstr -tabs 22                           
                                        $str += GenerateStr -str "</div>" -tabs 21
                                    }
                                }
                                elseif($paramType -eq "SwitchParameter"){
                                    $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                    $str += GenerateStr -str "<label id=`"$rec-RequiredLabel-$param-ParameterSet$indexcounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`">$param`:</label>" -tabs 22
                                    $str += GenerateStr -str "<div class=`"tooltip`" style=`"padding-bottom: 30px;`"><input type=`"checkbox`" id=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`" name=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`" value=`"true`"><label for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`"></label><span class=`"tooltiptext`">$paramexplanation</span></div>" -tabs 22
                                    $str += GenerateStr -str "</div>" -tabs 21
                                }
                                else{
                                    $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                    $str += GenerateStr -str "<label id=`"$rec-RequiredLabel-$param-ParameterSet$indexcounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`">$param`:</label>" -tabs 22
                                    $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`"><input style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`" name=`"$rec-RequiredParam-$param-ParameterSet$indexcounter`" placeholder=`"Enter $param Value Here...`"></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>" -tabs 22
                                    $str += GenerateStr -str "</div>" -tabs 21
                                }
                            }
                        }
                    }
                    #$ParamCounter += 1
                    $str += GenerateStr -str "</form>" -tabs 20
                    $str += GenerateStr -str "</div>" -tabs 19
                    $str += GenerateStr -str "</div>" -tabs 18
                    $str += GenerateStr -str "</div>" -tabs 17
                }
            }
            LogFile -fileName $fileName -str $str

        }
    }
}
function InitiateVarsInCSS{
    param($fileName)

    if($global:test){
        $AllCommands = @{
            name = @("Get-VPASEPVUserDetails","Get-VPASAccountDetails")
        }
    }
    else{
        $AllCommands = Get-Command -Module vpasmodule
    }

    foreach($rec in $AllCommands.name){
        if($rec -ne "New-VPASToken" -and $rec -ne "Write-VPASOutput"){
            $temprec = $rec -replace "-",""
            $ParamSets = (((Get-Command $rec)).ParameterSets.count) - 2
            $ParamCounter = 1
            while($ParamCounter -le $ParamSets + 1){
                $divoutput = "div$temprec" + "_ParameterSet$ParamCounter"
                $divoutput2 = "div$rec" + "-ParameterSet$ParamCounter"
                $divoutput3 = "divoptional$temprec" + "_ParameterSet$ParamCounter"
                $divoutput4 = "divoptional$rec" + "-ParameterSet$ParamCounter"

                $str = GenerateStrNoSpace -str "var $divoutput = document.getElementById('$divoutput2');" -tabs 3
                LogFile -fileName $fileName -str $str
                $str = GenerateStrNoSpace -str "var $divoutput3 = document.getElementById('$divoutput4');" -tabs 3
                LogFile -fileName $fileName -str $str

                $ParamCounter += 1
            }
        }
    }
}
function GenerateDropDownValues{
    param($fileName)

    if($global:test){
        $AllCommands = @{
            name = @("Get-VPASEPVUserDetails","Get-VPASAccountDetails")
        }
    }
    else{
        $AllCommands = Get-Command -Module vpasmodule
    }

    foreach($rec in $AllCommands.name){
        if($rec -ne "New-VPASToken" -and $rec -ne "Write-VPASOutput"){
            $str = GenerateStrNoSpace -str "<div data-value=`"$rec`">$rec</div>" -tabs 18
            LogFile -fileName $fileName -str $str
        }
    }
}
function GenerateIfStatementsInCSS{
    param($fileName)
    
    $first = $true

    if($global:test){
        $AllCommands = @{
            name = @("Get-VPASEPVUserDetails","Get-VPASAccountDetails")
        }
    }
    else{
        $AllCommands = Get-Command -Module vpasmodule
    }

    foreach($rec in $AllCommands.name){
        if($rec -ne "New-VPASToken" -and $rec -ne "Write-VPASOutput"){
            $temprec = $rec -replace "-",""

            #$ParamSets = (((Get-Command $rec)).ParameterSets.count) - 2
            #$ParamCounter = 1
            #while($ParamCounter -lt $ParamSets + 1){
                $divoutput = "div$temprec" + "_ParameterSet1"
                $divoutput2 = "divoptional$temprec" + "_ParameterSet1"
                if($first){
                    $str = GenerateStrNoSpace -str "if (input.value === '$rec') {$divoutput.style.display = 'block'; $divoutput2.style.display = 'block';}" -tabs 5
                    $first = $false
                }
                else{
                    $str = GenerateStrNoSpace -str "else if (input.value === '$rec') {$divoutput.style.display = 'block'; $divoutput2.style.display = 'block';}" -tabs 5
                }
                LogFile -fileName $fileName -str $str
            #}
        }
    }
}
function GetAllOptionalProps{
    param($fileName)

    $skipparams = @("token","Verbose","Debug","ErrorAction","WarningAction","InformationAction","ErrorVariable","WarningVariable","InformationVariable","OutVariable","OutBuffer","PipelineVariable")
    if($global:test){
        $AllCommands = @{
            name = @("Get-VPASEPVUserDetails","Get-VPASAccountDetails")
        }
    }
    else{
        $AllCommands = Get-Command -Module vpasmodule
    }

    foreach($rec in $AllCommands.name){
        $str = ""
        if($rec -ne "New-VPASToken" -and $rec -ne "Write-VPASOutput"){
            
            #$ParamSets = (((Get-Command $rec)).ParameterSets.count) - 2
            #$ParamCounter = 1

            $ParamCounter = 0
            $ParamSets = ((Get-Command $rec)).ParameterSets
            foreach($pset in $ParamSets){
                $SetName = $pset.Name
                if($SetName -eq "InputParameters"){
                    #DO NOTHING
                }
                else{
                    $ParamCounter += 1
                    $AllRequiredParams = $pset.parameters | Where-Object isMandatory -eq 0
                    $str += GenerateStr -str "<div id=`"divoptional$rec-ParameterSet$ParamCounter`" class=`"divCommands`" style=`"text-align: left; font-size: 12px; margin-left: 1%; display: none; width: 700px; padding-top: 10px;`">" -tabs 17
                    $str += GenerateStr -str "<div class=`"metrics-container-reverse`" style=`"width: 100%; padding-top: 0px;`">" -tabs 18
                    $str += GenerateStr -str "<div class=`"metric-reverse`"><p style=`"text-align: left; font-size: 14px; margin-bottom: 5px;`"><b>$rec : Optional Parameters (Set$ParamCounter)</b></p></div>" -tabs 19
                    $str += GenerateStr -str "<div class=`"metrics-container`" style=`"width: 100%;`">" -tabs 19
                    $str += GenerateStr -str "<form>" -tabs 20

                    if($AllRequiredParams.count -eq 0){
                        $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                        $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label id=`"$rec-OptionalLabel-NA-ParameterSet$ParamCounter`" for=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`"><input readonly style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" placeholder=`"NO OPTIONAL PARAMETERS`"></label><br><span class=`"requiredtooltiptext`">This command has NO optional parameters</span></div>" -tabs 22
                        $str += GenerateStr -str "</div>" -tabs 21
                    }
                    else{
                        $amtofparams = $AllRequiredParams.count
                        foreach($RequiredParam in $AllRequiredParams){
                            $AllInfo = Get-Help -Name $rec
                            $param = $RequiredParam.Name
                            $paramType = $RequiredParam.ParameterType.Name
                            $paramValidValues = $RequiredParam.Attributes.validvalues
                            $paramexplanation = "BLANK"

                            if(!$skipparams.Contains($param)){
                                foreach($tempparam in $AllInfo.parameters.parameter){
                                    $tempparamname = $tempparam.name
                                    $tempparamdescription = $tempparam.description.text

                                    if($tempparamname -eq $param){
                                        $paramexplanation = $tempparamdescription.replace("`n"," - ")
                                    }
                                }
                        
                                if($paramType -eq "String"){
                                    if($paramValidValues.count -eq 0){
                                        $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                        $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                        $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"><input style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" placeholder=`"Enter $param Value Here...`"></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>" -tabs 22
                                        $str += GenerateStr -str "</div>" -tabs 21
                                    }
                                    else{
                                        #MAKE A DROP DOWN
                                        $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                        $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                        $tempstr = "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"><select style=`"font-size: 12px; background-color: #4C5C96; background-size: 2rem;`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">"
                                        $tempstr += "<option value=`"Select value...`">Select value...</option>"
                                        foreach($validval in $paramValidValues){
                                            $tempstr += "<option value=`"$validval`">$validval</option>"

                                        }
                                        $tempstr += "</select></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>"
                                        $str += GenerateStr -str $tempstr -tabs 22                           
                                        $str += GenerateStr -str "</div>" -tabs 21
                                    }
                                }
                                elseif($paramType -eq "SwitchParameter"){
                                    $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                    $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                    $str += GenerateStr -str "<div class=`"tooltip`" style=`"padding-bottom: 30px;`"><input type=`"checkbox`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" value=`"true`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"></label><span class=`"tooltiptext`">$paramexplanation</span></div>" -tabs 22
                                    $str += GenerateStr -str "</div>" -tabs 21
                                }
                                else{
                                    $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                    $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                    $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"><input style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" placeholder=`"Enter $param Value Here...`"></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>" -tabs 22
                                    $str += GenerateStr -str "</div>" -tabs 21
                                }
                            }
                            else{
                                $amtofparams -= 1
                            }

                            if($amtofparams -eq 0){
                                $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label id=`"$rec-OptionalLabel-NA-ParameterSet$ParamCounter`" for=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`"><input readonly style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" placeholder=`"NO OPTIONAL PARAMETERS`"></label><br><span class=`"requiredtooltiptext`">This command has NO optional parameters</span></div>" -tabs 22
                                $str += GenerateStr -str "</div>" -tabs 21
                            }
                        }

                        $str += GenerateStr -str "</form>" -tabs 20
                        $str += GenerateStr -str "</div>" -tabs 19
                        $str += GenerateStr -str "</div>" -tabs 18
                        $str += GenerateStr -str "</div>" -tabs 17
                    }
                }
            }
            
            
            
            
            
            <#
            while($ParamCounter -le $ParamSets + 1){

                $AllRequiredParams = ((Get-Command $rec).ParameterSets)[$ParamCounter-1].parameters | Where-Object isMandatory -eq 0
            
                if($firstflag){
                    $str = GenerateStr -str "<div id=`"divoptional$rec-ParameterSet$ParamCounter`" class=`"divCommands`" style=`"text-align: left; font-size: 12px; margin-left: 1%; display: none; width: 700px; padding-top: 10px;`">" -tabs 17
                    $firstflag = $false
                }
                else{
                    $str += GenerateStr -str "<div id=`"divoptional$rec-ParameterSet$ParamCounter`" class=`"divCommands`" style=`"text-align: left; font-size: 12px; margin-left: 1%; display: none; width: 700px; padding-top: 10px;`">" -tabs 17
                }
            
                $str += GenerateStr -str "<div class=`"metrics-container-reverse`" style=`"width: 100%; padding-top: 0px;`">" -tabs 18
                $str += GenerateStr -str "<div class=`"metric-reverse`"><p style=`"text-align: left; font-size: 14px; margin-bottom: 5px;`"><b>$rec : Optional Parameters (Set$ParamCounter)</b></p></div>" -tabs 19
                $str += GenerateStr -str "<div class=`"metrics-container`" style=`"width: 100%;`">" -tabs 19
                $str += GenerateStr -str "<form>" -tabs 20

                if($AllRequiredParams.count -eq 0){
                    $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                    $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label id=`"$rec-OptionalLabel-NA-ParameterSet$ParamCounter`" for=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`"><input readonly style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" placeholder=`"NO OPTIONAL PARAMETERS`"></label><br><span class=`"requiredtooltiptext`">This command has NO optional parameters</span></div>" -tabs 22
                    $str += GenerateStr -str "</div>" -tabs 21
                }
                else{
                    $amtofparams = $AllRequiredParams.count
                    foreach($RequiredParam in $AllRequiredParams){
                        $AllInfo = Get-Help -Name $rec
                        $param = $RequiredParam.Name
                        $paramType = $RequiredParam.ParameterType.Name
                        $paramValidValues = $RequiredParam.Attributes.validvalues
                        $paramexplanation = "BLANK"

                        if(!$skipparams.Contains($param)){
                            foreach($tempparam in $AllInfo.parameters.parameter){
                                $tempparamname = $tempparam.name
                                $tempparamdescription = $tempparam.description.text

                                if($tempparamname -eq $param){
                                    $paramexplanation = $tempparamdescription.replace("`n"," - ")
                                }
                            }
                        
                            if($paramType -eq "String"){
                                if($paramValidValues.count -eq 0){
                                    $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                    $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                    $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"><input style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" placeholder=`"Enter $param Value Here...`"></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>" -tabs 22
                                    $str += GenerateStr -str "</div>" -tabs 21
                                }
                                else{
                                    #MAKE A DROP DOWN
                                    $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                    $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                    $tempstr = "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"><select style=`"font-size: 12px; background-color: #4C5C96; background-size: 2rem;`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">"
                                    $tempstr += "<option value=`"Select value...`">Select value...</option>"
                                    foreach($validval in $paramValidValues){
                                        $tempstr += "<option value=`"$validval`">$validval</option>"

                                    }
                                    $tempstr += "</select></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>"
                                    $str += GenerateStr -str $tempstr -tabs 22                           
                                    $str += GenerateStr -str "</div>" -tabs 21
                                }
                            }
                            elseif($paramType -eq "SwitchParameter"){
                                $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                $str += GenerateStr -str "<div class=`"tooltip`" style=`"padding-bottom: 30px;`"><input type=`"checkbox`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" value=`"true`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"></label><span class=`"tooltiptext`">$paramexplanation</span></div>" -tabs 22
                                $str += GenerateStr -str "</div>" -tabs 21
                            }
                            else{
                                $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                                $str += GenerateStr -str "<label id=`"$rec-OptionalLabel-$param-ParameterSet$ParamCounter`" style=`"align-items: center; margin-top: 10px; margin-right: 5px;`" for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`">$param`:</label>" -tabs 22
                                $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label for=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`"><input style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-$param-ParameterSet$ParamCounter`" placeholder=`"Enter $param Value Here...`"></label><br><span class=`"requiredtooltiptext`">$paramexplanation</span></div>" -tabs 22
                                $str += GenerateStr -str "</div>" -tabs 21
                            }
                        }
                        else{
                            $amtofparams -= 1
                        }

                        if($amtofparams -eq 0){
                            $str += GenerateStr -str "<div style=`"display: flex; margin-bottom: 5px;`">" -tabs 21
                            $str += GenerateStr -str "<div class=`"requiredtooltip`" style=`"width: 700px;`"><label id=`"$rec-OptionalLabel-NA-ParameterSet$ParamCounter`" for=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`"><input readonly style=`"font-size: 12px; background-color: #4C5C96;`" type=`"text`" id=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" name=`"$rec-OptionalParam-NA-ParameterSet$ParamCounter`" placeholder=`"NO OPTIONAL PARAMETERS`"></label><br><span class=`"requiredtooltiptext`">This command has NO optional parameters</span></div>" -tabs 22
                            $str += GenerateStr -str "</div>" -tabs 21
                        }
                    }

                    $ParamCounter += 1
                    $str += GenerateStr -str "</form>" -tabs 20
                    $str += GenerateStr -str "</div>" -tabs 19
                    $str += GenerateStr -str "</div>" -tabs 18
                    $str += GenerateStr -str "</div>" -tabs 17
                }
            }
            #>
            LogFile -fileName $fileName -str $str
        }
    }
}
function GenerateIfStatementsToGetParamLabelValues{
    param($fileName)
    
    $skipparams = @("token","Verbose","Debug","ErrorAction","WarningAction","InformationAction","ErrorVariable","WarningVariable","InformationVariable","OutVariable","OutBuffer","PipelineVariable","InputParameters")
    $firstcommand = $true

    if($global:test){
        $AllCommands = @{
            name = @("Get-VPASEPVUserDetails","Get-VPASAccountDetails")
        }
    }
    else{
        $AllCommands = Get-Command -Module vpasmodule
    }
    foreach($rec in $AllCommands.name){
        if($firstcommand){
            $str = GenerateStr -str "if(selectedCommand === `"$rec`"){" -tabs 4
            $firstcommand = $false
        }
        else{
            $str = GenerateStr -str "else if(selectedCommand === `"$rec`"){" -tabs 4
        }

        $paramsetSelectedNumber = 0
        $AllParamSets = (Get-Command $rec).ParameterSets
        foreach($pset in $AllParamSets){
            if($pset.Name -eq "InputParameters"){
                #DO NOTHING
            }
            else{
            
                $paramsetSelectedNumber += 1
            
                if($paramsetSelectedNumber -eq 1){
                    $str += GenerateStr -str "if (selectedSetNumber === `"$paramsetSelectedNumber`") {" -tabs 5
                }
                else{
                    $str += GenerateStr -str "else if (selectedSetNumber === `"$paramsetSelectedNumber`") {" -tabs 5
                }

                $AllRequiredParams = $pset.parameters | Where-Object isMandatory -eq 1
                foreach($RequiredParam in $AllRequiredParams){
                    $param = $RequiredParam.name
                    $paramtype = $RequiredParam.ParameterType.Name
            
                    if($param -eq "InputParameters"){
                        #DO NOTHING
                    }
                    else{
                        if($paramtype -eq "String"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-RequiredParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-RequiredLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' `"' + param + '`"'" -tabs 6
                        }
                        elseif($paramtype -eq "SwitchParameter"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-RequiredParam-$param-ParameterSet$paramsetSelectedNumber');" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-RequiredLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.checked){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                        elseif($paramtype -eq "Int32"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-RequiredParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-RequiredLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.length != 0){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' ' + param" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                            $str += GenerateStr -str "else{" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' 0'" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                        elseif($paramtype -eq "Hashtable"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-RequiredParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-RequiredLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.length != 0){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' @{'" -tabs 7
                            $str += GenerateStr -str "let strsplit = param.split(',')" -tabs 7
                            $str += GenerateStr -str "let strcount = 0" -tabs 7
                            $str += GenerateStr -str "while (strcount < strsplit.length){" -tabs 7
                            $str += GenerateStr -str "let templabel = strsplit[strcount]" -tabs 8
                            $str += GenerateStr -str "strcount++" -tabs 8
                            $str += GenerateStr -str "let tempparam = strsplit[strcount]" -tabs 8
                            $str += GenerateStr -str "strcount++" -tabs 8
                            $str += GenerateStr -str "LoginCommand = LoginCommand + templabel + '=`"' + tempparam + '`";'" -tabs 8
                            $str += GenerateStr -str "}" -tabs 7
                            $str += GenerateStr -str "LoginCommand = LoginCommand + '}'" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                        else{
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-RequiredParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-RequiredLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.length != 0){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' `"' + param + '`"'" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                    }
                }

                ###
                $AllOptionalParams = $pset.parameters | Where-Object isMandatory -eq 0
                foreach($OptionalParam in $AllOptionalParams){
                    $param = $OptionalParam.name
                    $paramtype = $OptionalParam.ParameterType.Name
                    if(!$skipparams.Contains($param)){
                        if($paramtype -eq "String"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-OptionalParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-OptionalLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.length != 0 && param != `"Select value...`"){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' `"' + param + '`"'" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                        elseif($paramtype -eq "SwitchParameter"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-OptionalParam-$param-ParameterSet$paramsetSelectedNumber');" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-OptionalLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.checked){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                        elseif($paramtype -eq "Int32"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-OptionalParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-OptionalLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.length != 0){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' ' + param" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                        elseif($paramtype -eq "Hashtable"){
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-OptionalParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-OptionalLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.length != 0){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' @{'" -tabs 7
                            $str += GenerateStr -str "let strsplit = param.split(',')" -tabs 7
                            $str += GenerateStr -str "let strcount = 0" -tabs 7
                            $str += GenerateStr -str "while (strcount < strsplit.length){" -tabs 7
                            $str += GenerateStr -str "let templabel = strsplit[strcount]" -tabs 8
                            $str += GenerateStr -str "strcount++" -tabs 8
                            $str += GenerateStr -str "let tempparam = strsplit[strcount]" -tabs 8
                            $str += GenerateStr -str "strcount++" -tabs 8
                            $str += GenerateStr -str "LoginCommand = LoginCommand + templabel + '=`"' + tempparam + '`";'" -tabs 8
                            $str += GenerateStr -str "}" -tabs 7
                            $str += GenerateStr -str "LoginCommand = LoginCommand + '}'" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                        else{
                            $str += GenerateStr -str "param = document.getElementById(selectedCommand + '-OptionalParam-$param-ParameterSet$paramsetSelectedNumber').value;" -tabs 6
                            $str += GenerateStr -str "label = (document.getElementById(selectedCommand + '-OptionalLabel-$param-ParameterSet$paramsetSelectedNumber').textContent).slice(0, -1);" -tabs 6
                            $str += GenerateStr -str "if(param.length != 0){" -tabs 6
                            $str += GenerateStr -str "LoginCommand = LoginCommand + ' -' + label + ' `"' + param + '`"'" -tabs 7
                            $str += GenerateStr -str "}" -tabs 6
                        }
                    }
                }
                $str += GenerateStr -str "}" -tabs 5
            }
        }
        $str += GenerateStr -str "}" -tabs 4       
        LogFile -fileName $fileName -str $str
    }
}

$inputfile = Get-Content -Path "C:\Users\Vman\Desktop\VRepo\VpasModule\NewVpasWebsite\scriptbuilder\Template-Page.html"
$outputfile = "C:\Users\Vman\Desktop\VRepo\VpasModule\NewVpasWebsite\scriptbuilder\ScriptBuilder.html"
write-output "<!-- VpasModule ScriptBuilder -->" | Set-Content $outputfile
$counter = 0

foreach($line in $inputfile){
    
    #SECTION1
    if($line -match "<!-- VADIM - ADD VARS FROM POWERSHELL HERE -->"){
        LogFile -fileName $outputfile -str $line
        $InitiateVarsInCSS = InitiateVarsInCSS -fileName $outputfile
        $counter += 1
        Write-Host "$counter) COMPLETED INTIATING VARS IN CSS SECTION" -ForegroundColor Green
    }

    #SECTION2
    elseif($line -match "<!-- VADIM - GENERATE IFs FROM POWERSHELL HERE -->"){
        LogFile -fileName $outputfile -str $line
        $GenerateIfStatementsInCSS = GenerateIfStatementsInCSS -fileName $outputfile
        $counter += 1
        Write-Host "$counter) COMPLETED GENERATING IF STATEMENTS IN CSS SECTION" -ForegroundColor Green
    }

    #SECTION3
    elseif($line -match "<!-- VADIM - GENERATE PARAM/LABEL VALUES FROM POWERSHELL HERE -->"){
        LogFile -fileName $outputfile -str $line
        $GenerateIfStatementsToGetParamLabelValues = GenerateIfStatementsToGetParamLabelValues -fileName $outputfile
        $counter += 1
        Write-Host "$counter) COMPLETED GENERATING IF STATEMENTS TO GET PARAM/LABEL VALUES IN CSS SECTION" -ForegroundColor Green
    }

    #SECTION4
    elseif($line -match "<!-- VADIM - RUN POWERSHELL SCRIPT TO GENERATE THE DROPDOWN VALUES BELOW -->"){
        LogFile -fileName $outputfile -str $line
        $GenerateDropDownValues = GenerateDropDownValues -fileName $outputfile
        $counter += 1
        Write-Host "$counter) COMPLETED GENERATING DROPDOWN VALUES" -ForegroundColor Green
    }

    #SECTION5
    elseif($line -match "<!-- VADIM - RUN POWERSHELL SCRIPT TO GENERATE THE REQUIRED DIVs BELOW -->"){
        LogFile -fileName $outputfile -str $line
        $GetAllRequiredProps = GetAllRequiredProps -fileName $outputfile
        $counter += 1
        Write-Host "$counter) COMPLETED GENERATING REQUIRED DIVS" -ForegroundColor Green
    }

    #SECTION6
    elseif($line -match "<!-- VADIM - RUN POWERSHELL SCRIPT TO GENERATE THE OPTIONAL DIVs BELOW -->"){
        LogFile -fileName $outputfile -str $line
        $GetAllOptionalProps = GetAllOptionalProps -fileName $outputfile
        $counter += 1
        Write-Host "$counter) COMPLETED GENERATING OPTIONAL DIVS" -ForegroundColor Green
    }

    else{
        LogFile -fileName $outputfile -str $line
    }
}

