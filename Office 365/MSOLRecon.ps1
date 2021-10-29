#Change Window Title
$host.ui.RawUI.WindowTitle = "MSOL Recon"
Clear-Host
Write-Host "MSOL Recon" -ForegroundColor Green
Write-Host "Use this script to gather all Office 365 resources"

#Create Output Directory
mkdir .\MSOLRecon

$MSOLModule = Get-Module MSOnline
if ($MSOLModule) 
    {
        Import-Module MSOnline
        Connect-MsolService
    }
else
    {
        Install-Module MSOnline
        Connect-MsolService
    }
#Gather Data
Write-Host "Gathering Users" -ForegroundColor Green
$MSOLUser = Get-MsolUser -All

Write-Host "Gathering Groups"
$MSOLGroups = Get-MsolGroup -All

