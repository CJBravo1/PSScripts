#Check for Admin Credentials
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential -Message "Enter Teams Credentials"
}
#Connect Teams
Connect-MicrosoftTeams -Credential $adminCreds
$TeamsTenant = get-cstenant

#if ($null -eq $TeamsTenant)
#{
#    Connect-MicrosoftTeams -Credential $adminCreds
#}

#Create Export Directory
mkdir $TeamsTenant.DisplayName
Set-Location $TeamsTenant.DisplayName
mkdir "Team Members"

#Export Teams
Write-Host "Gathering and Exporting Teams and Members" -ForegroundColor Green
$Teams = Get-Team
$Teams | Export-Csv -NoTypeInformation "allTeams.csv"

#Export Team Members
$teams | ForEach-Object {
        $TeamName = $_.Displayname
        $TeamMailName = $_.MailNickName
        Write-Host $TeamName -ForegroundColor Cyan
        Get-TeamUser -GroupId $_.GroupID | Export-Csv -NoTypeInformation ".\Team Members\$TeamMailName.csv"
    }