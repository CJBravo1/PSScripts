# Import Active Directroy module. Duh.
IMPORT-MODULE ActiveDirectory

# Import CSV file with user's display names. Column A, First Name. Column B, Last Name.
$names = import-csv -path .\managerdlupdate.csv


###################################################################################################
# Loop to pull in each user and get username info.
foreach ($name in $names ) 
{

    $FirstName = $name.FirstName
    $LastName = $name.LastName
    $DisplayName1 = "$FirstName $LastName"

    Try
    {
    # Creates a filter to find the User's Display name off of First and Last name.
    $Filter = "givenName -like ""*$($name.FirstName)*"" -and sn -like ""$($name.lastname)"""

    #Gets User information. Select-Object only selects the properties listed behind it. 
    $user = Get-AdUser -Filter $filter -Properties * | Select-Object sAMAccountName | Export-Csv .\output.csv -Append -NoTypeInformation
    }
    Catch
    {
    Write-Host "ERROR! $User was not added to the CSV!"
    }
    Write-Host "Successfully added $DisplayName1 to the CSV!"
    "`n"
    
}
##################################################################################################


##################################################################################################
# Removes all users from both Managers groups
Try
{
Get-ADGroupMember Managers | ForEach-Object {Remove-ADGroupMember Managers $_ -Confirm:$false}
}
Catch
{
Write-Host "ERROR! Could not remove all members from the Managers DL! Try again, jackass!" -ForegroundColor Red
}
Write-Host "Successfully removed all members from the Managers DL!"
"`n"


Try
{
Get-ADGroupMember "L&D Management Program" | ForEach-Object {Remove-ADGroupMember "L&D Management Program" $_ -Confirm:$false}
}
Catch
{
Write-Host "ERROR! Could not remove all members from the L&D Management Program DL! Try again, jackass!" -ForegroundColor Red
}
Write-Host "Successfully removed all members from the L&D Management Program DL!"
"`n"

###################################################################################################


###################################################################################################
# Import output from previous code black, to use as input.
$Output = Import-Csv -Path .\output.csv

foreach ($SAM in $Output)
{

# Sets the UserID to the first column in the output.csv
$UID = $SAM.sAMAccountName
$DisplayName2 = (Get-ADUser $UID).name


    # Adds the user into the two groups. 
    Try
    {
    Add-ADGroupMember -Identity Managers -Members $UID
    }
    Catch
    {
    Write-Host "ERROR! Could not add $UID to the Managers DL! Try again, jackass!" -ForegroundColor Red
    }
    Write-Host "Successfully added $DisplayName2 to the Managers DL!" 



    Try
    {
    Add-ADGroupMember -Identity "L&D Management Program" -Members $UID
    }
    Catch
    {
    Write-Host "ERROR! Could not add $UID to the L&D Management Program DL! Try again, jackass!" -ForegroundColor Red
    }
    Write-Host "Successfully added $DisplayName2 to the L&D Management Program DL!" 
    "`n"
}
###################################################################################################


Remove-Item .\output.csv -Recurse

# This block of code will pause the PowerShell window and keep it up. This way you can go over what the script actually did, and not auto-close the window. 
Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")