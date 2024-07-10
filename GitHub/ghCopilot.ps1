$wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue

if (-not $wingetInstalled) {
    Write-Host "winget is not installed. Installing winget..."
    $wingetInstallerUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/winget-cli.msixbundle"
    $wingetInstallerPath = "$env:TEMP\winget-cli.msixbundle"

    Invoke-WebRequest -Uri $wingetInstallerUrl -OutFile $wingetInstallerPath
    Add-AppxPackage -Path $wingetInstallerPath

    Write-Host "winget has been installed."
} else {
    Write-Host "winget is already installed."
}


#Install gh
winget install GitHub.cli



#Sign into GitHub
& "C:\Program Files\GitHub CLI\gh.exe" auth login

#Install github extension
& "C:\Program Files\GitHub CLI\gh.exe" extension install github/gh-copilot

#Add Alias to $PROFILE
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}

& 'C:\Program Files\GitHub CLI\gh.exe' copilot alias pwsh >> $PROFILE
