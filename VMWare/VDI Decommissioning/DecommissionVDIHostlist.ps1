#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\$CurrentUser"
}
#Connect to VMWare
$PowerCLIModule = Get-Module -ListAvailable VMWare.PowerCLI
Import-Module VMware.Hv.Helper

if ($null -ne $PowerCLIModule)
    {
         #Get VM ENvironment
         $VMEnvironment = $HOST.UI.RAWUI.WindowTitle

         if ($VMEnvironment -eq "VMWare VA")
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
        
        #Connect to VIServer. Set Environment Variables
        Switch ($VMEnvironment)
        {
            "MN"
            {
                Write-Host "Connecting to MN VI Server" -ForegroundColor Green
                $VIServer = "SERVER.DOMAIN.local"
                $Horizon = 'SERVER.DOMAIN.local'
                Write-Host "Duo Prompt Sent" -ForegroundColor Yellow -BackgroundColor Blue
                Connect-VIServer $VIServer -Credential $adminCreds
                $hvserver1 = Connect-HVServer $Horizon -Credential $adminCreds
                $services1=$hvserver1.extensiondata
            }
            "VA"
            {
                $VIServer = "SERVER.DOMAIN.local"
                $Horizon = 'SERVER.DOMAIN.local'
                Write-Host "Duo Prompts Sent" -ForegroundColor Yellow -BackgroundColor Blue
                Connect-VIServer $VIServer -Credential $adminCreds
                $hvserver1 = Connect-HVServer $Horizon -Credential $adminCreds
                $services1=$hvserver1.extensiondata
            }
        }

        #Get VM Information
        $VMList = Get-Content .\VMList.txt
        foreach ($Entry in $VMList )
        {                 
            $VM = Get-VM $Entry -ErrorAction SilentlyContinue
            if ($null -ne $vm)
            {
                #Get Datestamp
                $date = Get-Date -Format "MM/dd/yyyy"
                
                #Set VM to Maintenance Mode
                Set-HVMachine -MachineName $Entry -Maintenance ENTER_MAINTENANCE_MODE

                #Remove Assignment from VM
                Write-Host "Removing User From: $Entry" -ForegroundColor Green
                $machinename="$Entry"
                $machineid=(get-hvmachine -machinename $machinename).id
                $machineservice=new-object vmware.hv.machineservice
                $machineinfohelper=$machineservice.read($services1, $machineid)
                $machineinfohelper.getbasehelper().setuser($null)
                $machineservice.update($services1, $machineinfohelper)
                
                #Set VM Notes
                Write-Host "Setting VM Notes" -ForegroundColor Green 
                Set-VM $VM -Notes "AD User Disabled. Shutdown $date" -Confirm:$false

                #Remove VM from Pool
                Remove-HVMachine $VM.Name -Confirm:$false

                #Disable AD Record
                $DNS = (Get-VMGuest $vm).HostName
                $DNSRecord = $DNS.Replace(".SERVER.DOMAIN","")
                $ADRecord = Get-ADComputer $DNSRecord
                Write-Host "Disabling $ADRecord.DistinguishedName" -ForegroundColor Cyan
                Set-ADComputer $ADRecord.DistinguishedName -Enabled $false -Confirm:$false

                #Shutdown VM
                Write-Host "Stopping $vm" -ForegroundColor Green
                Stop-VM $vm -Confirm:$false

            }
        else
            {
                Write-Host "$Entry Not Found!" -ForegroundColor Yellow -BackgroundColor Red
            }
        }

    }