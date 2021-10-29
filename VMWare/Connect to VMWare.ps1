#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\$CurrentUser"
}
#Connect to VMWare
$PowerCLIModule = Get-Module -ListAvailable VMWare.PowerCLI
if ($null -ne $PowerCLIModule)
    {
    Import-Module VMware.Hv.Helper
    #Select VM Environment
    $VMEnvironment = $HOST.UI.RAWUI.WindowTitle
    if($VMEnvironment -eq "VMWare VA")
    {
        $VMEnvironment = "VA"
    }
    elseif ($VMEnvironment -eq "VMWare MN") 
    {
        $VMEnvironment = "MN"    
    }
    else 
    {
        $VMEnvironment = Read-Host "VM Environment? (MN or VA?)"
    }
    Switch ($VMEnvironment)
    {
        "MN"
        {
            Write-Host "Connecting to MN VDI Server" -ForegroundColor Green
            $VIServer = "SERVER.DOMAIN.local"
            $Horizon = 'SERVER.DOMAIN.local'
            Write-Host "Duo Prompt Sent" -ForegroundColor Yellow -BackgroundColor Blue
            Connect-VIServer $VIServer -Credential $adminCreds
            Connect-HVServer $Horizon -Credential $adminCreds
        }
        "VA"
        {
            Write-Host "Connecting to VA VDI Server" -ForegroundColor Green
            $VIServer = "SERVER.DOMAIN.local"
            $Horizon = 'SERVER.DOMAIN.local'
            Connect-VIServer $VIServer -Credential $adminCreds
            Connect-HVServer $Horizon -Credential $adminCreds
        }
    }
}