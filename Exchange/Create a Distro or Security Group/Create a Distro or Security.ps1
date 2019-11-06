#Created by Thanada Saygnarath#
#5/22/2017#

#Set variables based on input#
$Type = Read-Host "Distribution or Security:?"
$DeptCode = Read-Host "Enter 3 Letter Department Code:"
$Distrolistname = Read-Host "Enter Name of Distribution Group:"
$Distro = "[$DeptCode] $Distrolistname"
$externalemail = Read-Host "Do you want to allow external email to send to $distro? Yes/No:"


$psSession = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri http://exs41.accruent.com/powershell
Import-PSSession $psSession -AllowClobber

if ($type -eq "Security" ) {
New-DistributionGroup -Name "$Distro" -type "Security" -SamAccountName $Distrolistname -OrganizationalUnit accruent.com/acc_Security_Groups}
if ($type -eq "Distribution") {
New-DistributionGroup -Name "$Distro" -type "Distribution" -SamAccountName $Distrolistname -OrganizationalUnit accruent.com/acc_Distribution_Groups}
if ($externalemail -eq "Yes") {
Set-DistributionGroup -identity $distrolistname -RequireSenderAuthenticationEnabled $false}


#Forces a Sync on O365$
$DC = $env:LOGONSERVER -replace ‘\\’,""

repadmin /syncall $DC /APed

$script =
{
    Start-ADSyncSyncCycle -PolicyType Initial
}

Invoke-Command -ComputerName BOSCORPAADC -ScriptBlock $script

