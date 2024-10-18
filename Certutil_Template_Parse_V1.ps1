
$ListTemplate = certutil -v -template
$Unprivileged ="Domain Users","Everyone"
$Output =@()

#Splitting the Certutil Output by Template
foreach ($Template in ((($ListTemplate.Split("`n")| Select-Object -SkipLast 2 ) -join "`n" -split "Template\[\d+\]:") | Select-Object -Skip 1 )){
    $ProcessTemplate = [PSCustomObject]@{}
    
    #Splitting Each Template by Line
    foreach ($TemplateLine in ($Template.split([System.Environment]::NewLine) )) {
        
        #Skip if Empty Line, or [d] ObjectIds:, or [d Extension
        if ([string]::IsNullOrEmpty($TemplateLine.trim()) -or $TemplateLine -match "^\d+ ObjectIds:" -or $TemplateLine -match "^\d+ Extensions:" ){
                continue;
        }

        #Processing Extensions    
        if(($ProcessTemplate.psobject.properties | select -Last 1).name -match "TemplatePropExtensions" -and 
           ($TemplateLine -match "\s{2}Extension\[\d+\]:" -or
            $TemplateLine -match "^\s{4}")){
        
        #Replacing and Adding TemplatePropExtensions Old Values and New Extension Values
            ($ProcessTemplate.psobject.properties | select -Last 1).value = (($ProcessTemplate.psobject.properties | select -Last 1).value+"`n"+"$TemplateLine".trim()).trim()
        }

        #Split Each Template Line into Key, and Value
        elseif ($TemplateLine -match "^\s{2}" -and $TemplateLine -notmatch "^\s{3}" ) {
            $TemplateLineSplit = ($TemplateLine.split("=")).trim()
            $ProcessTemplate | Add-Member -MemberType NoteProperty -Name $TemplateLineSplit[0] -Value $TemplateLineSplit[1] -force
        }


        else{
            #Appending last Key Values
            ($ProcessTemplate.psobject.properties | select -Last 1).value = (($ProcessTemplate.psobject.properties | select -Last 1).value+"`n"+"$TemplateLine".trim()).trim()
        }
    }

    #Adding to Output
    $Output +=$ProcessTemplate

}


$Output

<#Vulnerable
$Output | Where-Object {$_.TemplatePropSubjectNameFlags -like "*CT_FLAG_ENROLLEE_SUPPLIES_SUBJECT -- 1*" -and
                        $_.TemplatePropSecurityDescriptor -match ( $Unprivileged -join '|') 
                        } |select-object "TemplatePropCommonName","TemplatePropValidityPeriod",
                        @{Name='Object IDs'; Expression={($_.'TemplatePropEKUS' -replace ("[\d.]","") -replace ("`n",",")).trim()}},
                        @{Name='Permissions'; Expression={(($_.TemplatePropSecurityDescriptor.split("`n") | select-object -skip 1 ) -join "`n"  )}} | fl
#>

