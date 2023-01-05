#Get Exchange Domains
$domains = Get-AcceptedDomain
$PrimaryDomain = $domains[0]

#Create Export Directory
$ExportDirectory = New-Item ".\$primaryDomain" -Type Directory
$MembersDirectory = New-Item -Path $ExportDirectory.FullName -Name "Members" -Type Directory -Verbose

#Get Distribution Groups
Write-Host "Gathering and Exporting Distribution Groups" -ForegroundColor Green
$TxtFile = cat .\Groups.txt

#Gather Members
foreach ($Group in $TxtFile)
{
    Write-Host "Processing $Group" -ForegroundColor Green
    $Group = Get-DistributionGroup -identity $Group
    $members = Get-DistributionGroupMember $Group.PrimarySMTPAddress
    $members | Select-Object identity,Alias,PrimarySMTPAddress,RecipientTypeDetails,Guid | Export-Csv -NoTypeInformation "$MembersDirectory\$group.csv"
}
