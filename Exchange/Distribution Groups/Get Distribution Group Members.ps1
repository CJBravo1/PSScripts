# Get Distribution Groups
$ExportDirectory = $(pwd).path
Write-Host "Gathering Distribution Groups" -ForegroundColor Green
$reconGroupExportDir = New-Item -Path $ExportDirectory -Name "ReconGroups" -ItemType Directory
$reconGroupMembersExportDir = New-Item -Path $reconGroupExportDir -Name "ReconGroupMembers" -ItemType Directory
$distroGroups = Get-DistributionGroup -ResultSize unlimited -warningaction SilentlyContinue
$distroGroups | Select-Object name,displayname,alias,primarysmtpaddress,EmailAddresses | Export-Csv -NoTypeInformation "$reconGroupExportDir\DistributionGroups.csv"
$totalGroups = $distroGroups.Count
$progress = 0
foreach ($group in $distroGroups) {
    $progress++
    Write-Progress -Activity "Exporting Distribution Groups" -Status "Progress: $progress / $totalGroups" -PercentComplete (($progress / $totalGroups) * 100)
    
    $groupName = $group.Alias
    $groupMembers = Get-DistributionGroupMember -Identity $group.PrimarySmtpAddress -ResultSize unlimited -warningaction SilentlyContinue
    $groupMembers | Export-Csv -NoTypeInformation "$reconGroupMembersExportDir\$groupName.csv"
}
