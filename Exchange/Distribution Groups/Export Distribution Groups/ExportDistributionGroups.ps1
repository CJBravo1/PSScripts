#Connect to Exchange
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$adminUN = ([ADSI]$sidbind).mail.tostring()
$adminSAM = $adminUN -split "@"
$adminSAM = $adminSAM[0]
$adminSAM = "a$adminSAM"
$ADServer = $env:LOGONSERVER -replace "\\",""
if ($null -eq $adminCreds)
{
$adminCreds = Get-Credential $adminSAM
}

if ($null -eq (Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.exchange"}))
{
    $exchange = New-PSSession -ConfigurationName Microsoft.exchange -ConnectionUri http://SERVER/powershell -Credential $adminCreds
    Import-PSSession $exchange
    $ActiveDirectory = New-PSSession -ComputerName $ADServer -Credential $adminCreds
    Import-Module ActiveDirectory -PSSession $ActiveDirectory
}

#Test Export Folder
$ExportFolder = Test-Path .\Export
if ($false -eq $ExportFolder)
{
    Write-Host "Creating Export Folder" -ForegroundColor Yellow
    mkdir Export
}
else 
{
    Write-Host "Clearning Export Folder" -ForegroundColor Yellow
    Remove-Item .\Export\* -Force
    mkdir Export
}

#Gather NON SECURITY Distribution Groups
mkdir ".\Export\GroupMembers"
Write-Host "Gathering Non-Security Distribution Groups" -ForegroundColor Green
$nonSecurityGroups = Get-DistributionGroup | Where-Object {$_.GroupType -notlike "*SecurityEnabled"}
Write-Host "Exporting Non Security Groups" -ForegroundColor Green
$nonSecurityGroups | Export-Csv -NoTypeInformation .\Export\NonSecurityGroups.csv -Verbose

#Gather Distribution Group Members and Export eagh group to its own csv file in the Export Folder
foreach ($group in $nonSecurityGroups)
{
    $groupName = $group.Name
    Write-Host "Processing $groupName" -ForegroundColor Cyan
    $groupMembers = Get-DistributionGroupMember -Identity "$group"
    $groupMembers | Export-Csv -NoTypeInformation ".\Export\GroupMembers\$groupName.csv"
}
Write-Host "Processed "$nonSecurityGroups.Count " Groups" -ForegroundColor Yellow