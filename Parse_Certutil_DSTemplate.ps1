$ListTemplate = certutil -v -dstemplate
$Output =@()

#Splitting the Certutil Output by Template
foreach ($Template in ((($ListTemplate.Split("`n")| Select-Object -SkipLast 1 ) -join "`n" -split "\[[^\]]+\]") | Select-Object -Skip 2 | Select-Object -SkipLast 1 )){
    $ProcessTemplate = [PSCustomObject]@{}
    


    #Splitting Each Template by Line
    foreach ($TemplateLine in ($Template.split([System.Environment]::NewLine) )) {
        
        #Skip if Empty Line, or [d] ObjectIds:, or [d Extension
        if ([string]::IsNullOrEmpty($TemplateLine.trim()) ){
                continue;
        }


        #Split Each Template Line into Key, and Value
        if ($TemplateLine -match '^\s*([^=]+)\s*=\s*("([^"]+)"|([^",\s]+))\s*([,\s]*(.*))?$' ) {
            $TemplateLineSplit = ($TemplateLine.split("=",2)).trim()
            $ProcessTemplate | Add-Member -MemberType NoteProperty -Name $TemplateLineSplit[0] -Value $TemplateLineSplit[1] -force

        }

        
        else{
            #Appending last Key Values
            ($ProcessTemplate.psobject.properties | select -Last 1).value = (($ProcessTemplate.psobject.properties | select -Last 1).value+"`n"+"$TemplateLine".trim()).trim()
        }
    }

    $Output +=$ProcessTemplate
}

$Output
