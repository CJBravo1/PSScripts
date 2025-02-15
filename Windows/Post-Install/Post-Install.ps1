# Post-Install.ps1
# This script performs post-installation tasks

#####Windows Installation Functions#####
function Remove-WindowsBloat {
    Get-AppxPackage -AllUsers | Where-Object {
        $_.Name -notlike "*Store*" -and
        $_.Name -notlike "*Photos*" -and
        $_.Name -notlike "*Calculator*" -and
        $_.Name -notlike "*StickyNotes*" -and
        $_.Name -notlike "*Paint*" -and
        $_.Name -notlike "*SoundRecorder*"
    } | Remove-AppxPackage -ErrorAction SilentlyContinue
    
}
function Install-WindowsUpdates 
{
    Write-Host "Checking for Windows Updates" -ForegroundColor Green
    Install-Module PSWindowsUpdate -Force -SkipPublisherCheck
    Import-Module PSWindowsUpdate
    Install-WindowsUpdate -AcceptAll
}

function Install-Winget {
        #Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        #Reset Windows Store. 
        wsreset -i
        $wingetPath = "https://aka.ms/getwinget"
        Add-AppxPackage -Path $wingetPath
    }

function Install-WingetApps 
{
    Write-Host "Checking for App Updates" -ForegroundColor Green
    winget upgrade --all --accept-package-agreements --accept-source-agreements

    Write-Host "Installing Apps" -ForegroundColor Green
    $apps = @(
        "Google.Chrome"
        "GitHub.cli"
        "Microsoft.OneDrive"
        "Microsoft.Powershell"
        "Microsoft.PowerToys"
        "Microsoft.VisualStudioCode"
        "Microsoft.WindowsTerminal"
        "Spotify.Spotify"
        "Valve.Steam"
    )

        foreach ($app in $apps) 
        {
            Write-Host "Installing $app" -ForegroundColor Green
            winget install --id $app  --accept-package-agreements --accept-source-agreements
        }

        Start-Job -ScriptBlock {winget install microsoft.office --accept-package-agreements --accept-source-agreements}
}

function Install-Optionals {
    # Prompt to install WSL
    $installWSL = Read-Host "Do you want to install Windows Subsystem for Linux (WSL)? (y/n)"
    if ($installWSL -eq 'y') {
        Write-Host "Installing WSL" -ForegroundColor Green
        wsl --install
    } else {
        Write-Host "Skipping WSL installation" -ForegroundColor Yellow
    }

    # Prompt to install Docker Desktop
    $installDocker = Read-Host "Do you want to install Docker Desktop? (y/n)"
    if ($installDocker -eq 'y') {
        Write-Host "Installing Docker Desktop" -ForegroundColor Green
        winget install --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "Skipping Docker Desktop installation" -ForegroundColor Yellow
    }

    # Prompt to install Tailscale
    $installTailscale = Read-Host "Do you want to install Tailscale? (y/n)"
    if ($installTailscale -eq 'y') {
        Write-Host "Installing Tailscale" -ForegroundColor Green
        winget install --id Tailscale.Tailscale --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host "Skipping Tailscale installation" -ForegroundColor Yellow
    }

    # Prompt to install Hyper-V
    $installHyperV = Read-Host "Do you want to install Hyper-V? (y/n)"
    if ($installHyperV -eq 'y') {
        Write-Host "Installing Hyper-V" -ForegroundColor Green
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    } else {
        Write-Host "Skipping Hyper-V installation" -ForegroundColor Yellow
    }
}

#####Windows Configuration Functions#####
function Set-UACSettings
{
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0
}

function Disable-Telemetry {
    Write-Host "Disabling Windows Telemetry and Monitoring" -ForegroundColor Green

    # Disable telemetry services
    Get-Service -Name "DiagTrack", "dmwappushservice" | Stop-Service -Force
    Get-Service -Name "DiagTrack", "dmwappushservice" | Set-Service -StartupType Disabled

    # Disable telemetry tasks
    $tasks = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Autochk\Proxy",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "\Microsoft\Windows\Maintenance\WinSAT",
        "\Microsoft\Windows\Media Center\ActivateWindowsSearch",
        "\Microsoft\Windows\Media Center\ConfigureInternetTimeService",
        "\Microsoft\Windows\Media Center\DispatchRecoveryTasks",
        "\Microsoft\Windows\Media Center\ehDRMInit",
        "\Microsoft\Windows\Media Center\InstallPlayReady",
        "\Microsoft\Windows\Media Center\mcupdate",
        "\Microsoft\Windows\Media Center\MediaCenterRecoveryTask",
        "\Microsoft\Windows\Media Center\ObjectStoreRecoveryTask",
        "\Microsoft\Windows\Media Center\OCURActivate",
        "\Microsoft\Windows\Media Center\OCURDiscovery",
        "\Microsoft\Windows\Media Center\PBDADiscovery",
        "\Microsoft\Windows\Media Center\PBDADiscoveryW1",
        "\Microsoft\Windows\Media Center\PBDADiscoveryW2",
        "\Microsoft\Windows\Media Center\PvrRecoveryTask",
        "\Microsoft\Windows\Media Center\PvrScheduleTask",
        "\Microsoft\Windows\Media Center\RegisterSearch",
        "\Microsoft\Windows\Media Center\ReindexSearchRoot",
        "\Microsoft\Windows\Media Center\SqlLiteRecoveryTask",
        "\Microsoft\Windows\Media Center\UpdateRecordPath"
    )

    foreach ($task in $tasks) {
        if (Get-ScheduledTask -TaskPath $task -ErrorAction SilentlyContinue) {
            Disable-ScheduledTask -TaskPath $task -Verbose
        }
    }

    # Disable telemetry settings
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0
}

function Disable-XboxGameBar {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "GameDVR_Enabled" -Value 0
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "Enabled" -Value 0
}

function Set-WindowSnapping
{
    # Disable all window snapping settings except "When I snap a window, suggest what I can snap next to it"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -Value 1
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DockMoving" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DockMovingEnabled" -Value 0
}

function Set-TaskBarSettings
{
    Write-Host "Setting Search Box Settings" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0
    
    Write-Host "Hiding Task View button" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

    Write-Host "Hiding People button" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowPeople" -Value 0

    Write-Host "Hiding Windows Ink Workspace button" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowWindowsInkWorkspaceButton" -Value 0

    Write-Host "Hiding Touch Keyboard button" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTouchKeyboardButton" -Value 0

    Write-Host "Hiding Start Menu apps list" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowStartMenuAppsList" -Value 0

    Write-Host "Hiding Start Menu app list" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowStartMenuAppList" -Value 0

    Write-Host "Hiding Copilot button" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0

    Write-Host "Hiding Weather button" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0

    Write-Host "Unpinning all items from the taskbar except File Explorer and Microsoft Edge" -ForegroundColor Green
    $taskbarItems = (New-Object -ComObject Shell.Application).Namespace(0).Items() | Where-Object { $_.IsPinnedToTaskbar }
    foreach ($item in $taskbarItems) {
        if ($item.Name -ne "File Explorer" -and $item.Name -ne "Microsoft Edge") {
            $item.InvokeVerb("taskbarunpin")
        }
    }
    
    Write-Host "Moving all items to the left of the taskbar" -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0

    Write-Host "Pinning File Explorer to the taskbar" -ForegroundColor Green
    $Path = (New-Object -ComObject Shell.Application).Namespace(0).ParseName("explorer.exe").Path
    $null = (New-Object -ComObject Shell.Application).Namespace(0).ParseName($Path).InvokeVerb("taskbarpin")
}



#Start of script

#Configure Windows
Write-Host "Setting UAC Settings" -ForegroundColor Cyan
Set-UACSettings

Write-Host "Disabling Telemetry" -ForegroundColor Cyan
Disable-Telemetry

Write-Host "Setting Window Snapping Settings" -ForegroundColor Cyan
Set-WindowSnapping

Write-Host "Setting Taskbar Settings" -ForegroundColor Cyan
Set-TaskBarSettings

Write-Host "Disabling Xbox Game Bar" -ForegroundColor Cyan
Disable-XboxGameBar

#App Installations
Write-Host "Installing Windows Updates" -ForegroundColor Cyan
Start-Job -ScriptBlock { Install-WindowsUpdates }

Write-Host "Removing Windows Bloatware" -ForegroundColor Cyan
Remove-WindowsBloat

Write-Host "Installing Winget" -ForegroundColor Cyan
Install-Winget

Write-Host "Installing Winget Apps" -ForegroundColor Cyan
Install-WingetApps

Write-Host "Installing Optional Components" -ForegroundColor Cyan
Install-Optionals

Write-Host "Windows Configuration Complete!" -ForegroundColor Cyan