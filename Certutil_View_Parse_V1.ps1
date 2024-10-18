
#Use On CA
$ListCert = certutil -view 
$Output = @()

#Splitting by Row segment, Skipping Schema and Statistics
foreach ($Row in (($ListCert.Split("`n") -join "`n" -split "Row\s\d+:")) | Select-Object -Skip 1 |Select-Object -Skiplast 1){
    $RowProcess = [PSCustomObject]@{}
    $ExtensionProcess=[pscustomobject]@{}
    
    #Splitting each row to lines
    foreach ($RowLine in ($Row.split([System.Environment]::NewLine) )) {
        
        #Skipping Empty lines
        if ([string]::IsNullOrEmpty($RowLine) ){
            continue
        }

        #Splitting each line to Object
        if ($RowLine -match "^\s{2}" -and $RowLine -notmatch "^\s{3}" ) {
            $RowLineSplit = ($RowLine.split(":")).trim()
            $RowProcess | Add-Member -MemberType NoteProperty -Name $RowLineSplit[0] -Value $RowLineSplit[1] -force
        }
        
        #Processing Certificate Extensions 
        elseif(($RowProcess.psobject.properties | select -Last 1).name -match "Certificate Extensions" ){
            
            #Skipping Extension oid
            if ($RowLine.trim() -match "^\d\." ){
                continue
            }

            #Certificate Extensions to Objects
            if($RowLine -match "^\s{4}" -and $RowLine -notmatch "^\s{5}" ){
                $ExtensionProcess| Add-Member -MemberType NoteProperty -Name $RowLine.trim() -value ""
            }
            else {
                #Adding Certificates Extensions Values
                ($ExtensionProcess.psobject.properties | select -Last 1).value = (($ExtensionProcess.psobject.properties | select -Last 1).value+"`n"+("$RowLine").trim()).trim()

                #Replacing Processed Certificate Extension Objects to the Main Array 
                ($RowProcess.psobject.properties | select -Last 1).value = $ExtensionProcess
            }
 
        }
        else {
            #Adding Processed Objects to Main Array
            ($RowProcess.psobject.properties | select -Last 1).value = (($RowProcess.psobject.properties | select -Last 1).value+"`n"+"$RowLine".trim()).trim()
        }
    }

    #Adding The main array to result
    $Output += $RowProcess
}


#Full Output
$Output | fl

<#
To Get specific column, use the example below

$Output | Select-Object 'Request ID','Certificate Extensions' | fl

If you want to list each extensions use the example below

$Output |Select-Object "Requester Name", "Request ID" ,@{Name='Certificate Extensions Key Usage'; Expression={$_.'Certificate Extensions'.'Key Usage'}} | fl

$Output | Select-Object "Requester Name", "Request ID" ,@{Name='YourKeyName'; Expression={$_.'Certificate Extensions'.'Application Policies'}} | Where-Object {$_.'YourKeyName' -like "*Client Auth*"}

#>
  



