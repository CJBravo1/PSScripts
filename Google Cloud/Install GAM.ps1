#Check for Winget
$winget = Get-Command winget -ErrorAction SilentlyContinue 
if ($null -eq $winget)
{
    Write-Host "Installing Winget" -ForegroundColor Green
    Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/download/v1.3.2691/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
    Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
    Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
}

# Install Google Cloud SDK
Write-Host "Installing Google Cloud SDK" -ForegroundColor Green
winget install Google.CloudSDK

# Install gam
Write-Host "Installing GAM" -ForegroundColor Green
Invoke-WebRequest -Uri "https://github.com/GAM-team/GAM/releases/download/v6.50/gam-6.50-windows-x86_64.msi" -OutFile "$env:USERPROFILE\Downloads\gam-6.50-windows-x86_64.msi"
& "$env:userprofile\downloads\gam-6.50-windows-x86_64.msi" /qb

Write-Host "Follow the GAM Install Process..." -ForegroundColor Yellow