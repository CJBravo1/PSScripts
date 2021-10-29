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
            $VIServer = "SERVER.DOMAIN.local"
            $Horizon = 'SERVER.DOMAIN.local'
            Write-Host "Duo Prompt Sent" -ForegroundColor Yellow -BackgroundColor Blue
            Connect-VIServer $VIServer -Credential $adminCreds
            $hvserver = Connect-HVServer $Horizon -Credential $adminCreds
            $services1=$hvserver.extensiondata
        }
        "VA"
        {
            $VIServer = "SERVER.DOMAIN.local"
            $Horizon = 'SERVER.DOMAIN.local'
            Connect-VIServer $VIServer -Credential $adminCreds
            $hvserver = Connect-HVServer $Horizon -Credential $adminCreds
            $services1=$hvserver.extensiondata
        }
    }
    Write-Host "Gathering Virtual Machines" -ForegroundColor Green
    $HVMachines = Get-HVMachineSummary
    foreach ($Machine in $HVMachines) 
    {
        $user = $Machine.NamesData.UserName
        if ($null -ne $user)
        {
            $user = $user.Replace("SERVER.DOMAIN\","")
            $ADUser = Get-ADUser -Identity $user 
            if ($ADUser.Enabled -eq $false)
            {
                Write-Host "Processing $user" -ForegroundColor Green
                #Get Datestamp
                $date = Get-Date -Format "MM/dd/yyyy"

                #Set VM to Maintenance Mode
                $VM = $Machine.base.name
                Write-Host "Setting $vm to Maintenance Mode" -ForegroundColor Green
                Set-HVMachine -MachineName $VM -Maintenance ENTER_MAINTENANCE_MODE

                #Remove Assignment from VM
                Write-Host "Removing User From: $VM" -ForegroundColor Green
                $machinename="$VM"
                $machineid=(get-hvmachine -machinename $machinename).id
                $machineservice=new-object vmware.hv.machineservice
                $machineinfohelper=$machineservice.read($services1, $machineid)
                $machineinfohelper.getbasehelper().setuser($null)
                $machineservice.update($services1, $machineinfohelper)

                #Remove VM from Pool
                Remove-HVMachine $VM -Confirm:$false

                #Set VM Notes
                Write-Host "Setting VM Notes" -ForegroundColor Green
                Set-VM $Machine.base.name -Notes "AD User Disabled. Shutdown $date" -Confirm:$false

                #Disable AD Record
                $DNS = (Get-VMGuest $vm).HostName
                $DNSRecord = $DNS.Replace(".SERVER.DOMAIN","")
                $ADRecord = Get-ADComputer $DNSRecord
                Write-Host "Disabling $ADRecord.DistinguishedName" -ForegroundColor Cyan
                Set-ADComputer $ADRecord.DistinguishedName -Enabled $false -Confirm:$false

                #Shutdown VM
                Write-Host "Stopping $vm" -ForegroundColor Green
                Stop-VM $vm -Confirm:$false

                Write-Host 'Checking for other Disabled Users' -ForegroundColor Green
            }
        }
    }
    Write-Host "Script Complete..." -ForegroundColor Green
}