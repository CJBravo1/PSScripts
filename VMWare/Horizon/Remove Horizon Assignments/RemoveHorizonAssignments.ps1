#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\$CurrentUser"
}

#Get VM ENvironment
$VMEnvironment = $HOST.UI.RAWUI.WindowTitle
if ($VMEnvironment -notlike "VMWare*")
{
    $VMEnvironment = Read-Host "VM Environment? (MN or VA?)"
    $VMEnvironment = "VMWare $VMEnvironment"
}

Switch ($VMEnvironment)
{
    "VMWare VA"
    {
    $VMEnvironment = "VA"
    $HVServer = 'SERVER.DOMAIN.local'
    }
    "VMWare MN"
    {
    $VMEnvironment = "MN"
    $HVServer = 'SERVER.DOMAIN.local'
    }

}


$hvserver1=connect-hvserver "$HVServer" -Credential $adminCreds
$services1=$hvserver1.extensiondata

#Get VM List
$VMList = Read-Host 'Enter VM Name'

#Start Foreach Loop
foreach ($HVMachine in $VMList)
{
    Write-Host "Removing User From: $HVMachine" -ForegroundColor Cyan
    $machinename="$HVMachine"
    $machineid=(get-hvmachine -machinename $machinename).id
    $machineservice=new-object vmware.hv.machineservice
    $machineinfohelper=$machineservice.read($services1, $machineid)
    $machineinfohelper.getbasehelper().setuser($null)
    $machineservice.update($services1, $machineinfohelper)
}