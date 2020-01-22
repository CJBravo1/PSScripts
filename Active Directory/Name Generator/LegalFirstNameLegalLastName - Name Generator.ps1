#Variables
$InputFile = "C:\Data\NameGenerationFile.csv"
$OutputFile = "C:\Data\Name Generation Output\LegalFirstName-LegalLastName-NameGeneration.csv"


#Initialize Script Variables
$NameTable = @()

Import-CSV -Path $InputFile | Foreach{

    #Initialize Per user Variables
    $UniqueID = $null
    $GlobalID = $null
    $PreferredFirstName = $null
    $PreferredLastName = $null
    $LegalFirstName = $null
    $LegalLastName = $null
    $FirstName = $null
    $LastName = $null
    $OriginalName = $null
    $TruncatedName = $null
    $FinalNamePrefix = $null
    $NamePrefixCalculation = $null
    $NamePrefix = $null
    $Count = 1
  
    #Define input variables
    $UniqueID = $_.UniqueID
    $GlobalID = $_.UID
    $LegalFirstName = $_.FirstName
    $LegalLastName = $_.LastName

    #Name Calculation to use Legal first & last names.
    
    #FirstName
    $FirstName = $LegalFirstName

    #LastName
    $LastName = $LegalLastName
    
    #Track the original name
    $OriginalName = "$FirstName.$LastName"
   
    #Character Replace Criteria
    $NamePrefixCalculation = "$OriginalName" -replace '\s+',''
    $NamePrefixCalculation = $NamePrefixCalculation -replace '-',''

    If($NamePrefixCalculation -Contains "č"){$NamePrefix = $NamePrefix -iReplace 'č', 'c'}
    If($NamePrefixCalculation -Contains "á"){$NamePrefix = $NamePrefix -iReplace 'á', 'a'}
    If($NamePrefixCalculation -Contains "ý"){$NamePrefix = $NamePrefix -iReplace 'ý', 'y'}
    If($NamePrefixCalculation -Contains "í"){$NamePrefix = $NamePrefix -iReplace 'í', 'i'}
    If($NamePrefixCalculation -Contains "Š"){$NamePrefix = $NamePrefix -iReplace 'Š', 'S'}
    If($NamePrefixCalculation -Contains "č"){$NamePrefix = $NamePrefix -iReplace 'š', 's'}
    If($NamePrefixCalculation -Contains "n"){$NamePrefix = $NamePrefix -iReplace 'ň', 'n'}
    If($NamePrefixCalculation -Contains "ř"){$NamePrefix = $NamePrefix -iReplace 'ř', 'r'}
    If($NamePrefixCalculation -Contains "Ž"){$NamePrefix = $NamePrefix -iReplace 'Ž', 'Z'}
    If($NamePrefixCalculation -Contains "ö"){$NamePrefix = $NamePrefix -iReplace 'ö', 'o'}
    If($NamePrefixCalculation -Contains "ñ"){$NamePrefix = $NamePrefix -iReplace 'ñ', 'n'}
    If($NamePrefixCalculation -Contains "ä"){$NamePrefix = $NamePrefix -iReplace 'ä', 'a'}
    If($NamePrefixCalculation -Contains "ù"){$NamePrefix = $NamePrefix -iReplace 'ù', 'u'}
    If($NamePrefixCalculation -Contains "ó"){$NamePrefix = $NamePrefix -iReplace 'ó', 'o'}
    If($NamePrefixCalculation -Contains "ç"){$NamePrefix = $NamePrefix -iReplace 'ç', 'c'}
    If($NamePrefixCalculation -Contains "ß"){$NamePrefix = $NamePrefix -iReplace 'ß', 'B'}
    If($NamePrefixCalculation -Contains "ü"){$NamePrefix = $NamePrefix -iReplace 'ü', 'u'}
    If($NamePrefixCalculation -Contains "é"){$NamePrefix = $NamePrefix -iReplace 'é', 'e'}
    If($NamePrefixCalculation -Contains "ú"){$NamePrefix = $NamePrefix -iReplace 'ú', 'u'}
    If($NamePrefixCalculation -Contains "ž"){$NamePrefix = $NamePrefix -iReplace 'ž', 'z'}
    If($NamePrefixCalculation -Contains "ł"){$NamePrefix = $NamePrefix -iReplace 'ł', 'l'}
    If($NamePrefixCalculation -Contains "ë"){$NamePrefix = $NamePrefix -iReplace 'ë', 'e'}
    If($NamePrefixCalculation -Contains "ů"){$NamePrefix = $NamePrefix -iReplace 'ů', 'u'}
    If($NamePrefixCalculation -Contains "ě"){$NamePrefix = $NamePrefix -iReplace 'ě', 'e'}

    #Identify if string requires to be truncated
    If($NamePrefixCalculation.Length -gt 20){
        $NamePrefix = $NamePrefixCalculation.Substring(0,20)
        $TruncatedName = $NamePrefix
        }
    
    Else{$NamePrefix = $NamePrefixCalculation}
        
    #Add incremental counts to names that are duplicates.
    If($NameTable -contains $NamePrefix){

        #If length is 20 characters, truncate to 19 to allow for incremental addition of numbers
        If($NamePrefix.Length -eq 20){
            $NamePrefix = $NamePrefix.Substring(0,19)
            }
        
        #Until NameTable -Contains NamePrefix = $False, Continue to add a number and validate it exists.        
        Do{
            
            #Support for adding an additional digit over "9"
            If($Count -eq 10 -and $NamePrefix.length -ge 20){$NamePrefix = $NamePrefix.Substring(0,18)}
            
            #Support for adding an additional digit over "99"
            If($Count -eq 100 -and $NamePrefix.length -ge 20){$NamePrefix = $NamePrefix.Substring(0,17)}
            
            #Add the new integer to the name prefix, and evaluate the uniqueness of the name prefix again.
            $FinalNamePrefix = $null
            $FinalNamePrefix = $NamePrefix + $Count++
            }
        
        #Perform the the Do statement above  until the array table does not contain the new username.
        Until($NameTable -notcontains $FinalNamePrefix)
        }
    Else{$FinalNamePrefix = $NamePrefix}

    #Add the unique value to the array.
    $NameTable += $FinalNamePrefix
    
    #Output unique name to file.
    $Template = $null
    $Template = "$UniqueID|$GlobalID|$OriginalName|$TruncatedName|$FinalNamePrefix"

    #Native outputs do not support special characters, set UTF8 to avoid invalid characters in outputted data.
    Add-Content -Path $OutputFile -Value $Template -Encoding UTF8
    }