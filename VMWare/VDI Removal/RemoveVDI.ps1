#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\a$CurrentUser"
}

#Connect to ActiveDirectory
$PSSession = Get-PSSession | Where-Object {$_.ComputerName -like "*ADDS*"}
if ($null -eq $PSSession)
    {
    Write-Host "Connecting to Active Directory" -ForegroundColor Green
    $ADServer = $env:LOGONSERVER -replace "\\",""
    $ActiveDirectory = New-PSSession -ComputerName $ADServer -Credential $adminCreds
    Import-Module ActiveDirectory -PSSession $ActiveDirectory
    }
else 
    {
    Write-Host "Already Connected to Active Directory" -ForegroundColor Green
    }
    Import-Module VMware.Hv.Helper

#Connect to VMWare
$PowerCLIModule = Get-Module -ListAvailable VMWare.PowerCLI


if ($null -ne $PowerCLIModule)
    {
         #Get VM Information
         $VMUserInput = Read-Host "Enter VM Name"
         
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
                Connect-HVServer $Horizon -Credential $adminCreds
            }
            "VA"
            {
                $VIServer = "SERVER.DOMAIN.local"
                $Horizon = 'SERVER.DOMAIN.local'
                Write-Host "Duo Prompts Sent" -ForegroundColor Yellow -BackgroundColor Blue
                Connect-VIServer $VIServer -Credential $adminCreds
                Connect-HVServer $Horizon -Credential $adminCreds
            }
        }
        $VM = Get-VM $VMUserInput -ErrorAction SilentlyContinue
        if ($null -ne $vm)
        {
            #Gather VM Information
            $VMName = $VM.Name
            $HVMachine = Get-HVMachineSummary -MachineName $VMName
            $HVAssignedUser = $HVMachine.NamesData.UserName
            $HVAssignedUser = $HVAssignedUser.Replace("DOMAIN.local\","")

            #Remove AD Record
            Write-Host "Deleting Active Directory Record for $VMName" -ForegroundColor Green
            $DNS = (Get-VMGuest $vmname).HostName
            $DNSRecord = $DNS.Replace(".DOMAIN.local","")
            $ADRecord = Get-ADComputer $DNSRecord

            Write-Host $ADRecord.DistinguishedName -ForegroundColor Cyan
            Remove-ADComputer $ADRecord.DistinguishedName

            #Remove from Horizon
            Write-Host "Removing Horizon View Record" -ForegroundColor Green
            Remove-HVMachine -MachineNames $VMName

            #Stop Virtual Machine
            Write-Host "Stopping Virtual Machine" -ForegroundColor Green
            Stop-VM $VMName -Confirm:$false

            #Remove VM
            Write-Host "Deleting VM" -BackgroundColor Red -ForegroundColor Yellow
            Remove-VM $VMName -DeletePermanently

            #Remove User From AD Group
            if ($VMUserInput -like "SVDI*")
            {
                Write-Host "Removing User from GROUP AD Group" -ForegroundColor Green
                Remove-ADGroupMember -Identity GROUP -Members $HVAssignedUser
                if ($VMUserInput -like "SVDIMN*")
                {
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUsers
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUser

                }
                elseif ($VMUserInput -like "SVDIVA*")
                {
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUser
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUser
                }
            }

            elseif ($VMUserInput -like "PVDI*")
            {
                Write-Host "Removing User from GROUP AD Group" -ForegroundColor Green
                Remove-ADGroupMember -Identity GROUP -Members $HVAssignedUser
                if ($VMUserInput -like "PVDIMN*")
                {
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUser
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUser

                }
                elseif ($VMUserInput -like "SVDIVA*")
                {
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUser
                    Remove-ADGroupMember -Identity "GROUP" -Members $HVAssignedUser
                }
            }
            

            #Confirm Deletion
            #Confirm AD Deletion
            if ($null -eq (Get-ADComputer $DNSRecord -ErrorAction SilentlyContinue))
            {
                Write-Host "$VMName has been removed from AD" -ForegroundColor Green
            }
            else {Write-Host "AD Record for $VMName still exists" -ForegroundColor Yellow}

            #Confirm Horizon Deletion
            if ($null -eq (Get-HVMachine -MachineName $VMName -ErrorAction SilentlyContinue))
            {
                Write-Host "$VMName removed from VMWare Horizon" -ForegroundColor Green
            }
            else {Write-Host "Horizon Record for $VMName still exists" -ForegroundColor Yellow }

            #Confirm VSphere Deletion
            if ($null -eq ($VM = Get-VM $VMUserInput -ErrorAction SilentlyContinue))
            {
                Write-Host "$VMName has been removed from VMWare VSphere" -ForegroundColor Green
            }
            else {Write-Host "Virtual Machine $VMName still exists!" -ForegroundColor Yellow}
        }
        else
            {
                Write-Host "VM Not Found!" -ForegroundColor Yellow -BackgroundColor Red
            }

    }