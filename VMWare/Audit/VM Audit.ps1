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
            Write-Host "Connecting to MN VI Server" -ForegroundColor Green
            $VIServer = "SERVER\DOMAIN.local"
            $Horizon = 'SERVER.DOMAIN.local'
            Write-Host "Duo Prompt Sent" -ForegroundColor Yellow -BackgroundColor Blue
            Connect-VIServer $VIServer -Credential $adminCreds
            Connect-HVServer $Horizon -Credential $adminCreds
        }
        "VA"
        {
            $VIServer = "SERVER\DOMAIN.local"
            $Horizon = 'SERVER.DOMAIN.local'
            Connect-VIServer $VIServer -Credential $adminCreds
            Connect-HVServer $Horizon -Credential $adminCreds
        }
    }
    #Create Table
    $Table = @()

    #Gather Virtual Machines
    Write-Host "Gathering Virtual Machines"
    $VMList = Get-Content C:\Temp\vmlist.txt
    
    
    #Start VM Foreach loop
    foreach ($VirtualMachine in $VMList)
    {
        #Clear Table Row
        $TableRow = New-Object PSObject
        
        #Gather Data
        Write-Host "Processing $VirtualMachine" -ForegroundColor Green
        $VDI = Get-VM $VirtualMachine
        $VMView = Get-View $VDI
        $VMGuest = Get-VMGuest $VDI
        $HVMachine = Get-HVMachineSummary -MachineName $VDI
        $InstallDate = Invoke-VMScript -VM $VDI -ScriptText {([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).InstallDate)} -ScriptType PowerShell -GuestCredential $adminCreds
        $InstallDate = $InstallDate.ScriptOutput.Trim()

        #Add Table Values
        $TableRow | Add-Member -NotePropertyName "VMName" -NotePropertyValue $VDI.Name
        $TableRow | Add-Member -NotePropertyName "VM Hostname" -NotePropertyValue $VMGuest.HostName
        $TableRow | Add-Member -NotePropertyName "Assigned User" -NotePropertyValue $HVMachine.NamesData.UserName
        $TableRow | Add-Member -NotePropertyName "OS Install Date" -NotePropertyValue $InstallDate
        

        #Export Table
        $Table += ($TableRow)
        $Table | Export-Csv -NoTypeInformation .\Export.csv -Append 
    }
    
}
