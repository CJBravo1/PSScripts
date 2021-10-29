#Import CSV
$VMList = Import-Csv .\VMList.csv -ErrorAction Stop

#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\$CurrentUser"
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
        #Create new VDI Array
        $NewVDIArray = @()

        #Start Foreach Loop
        foreach ($VMItem in $VMList)
        {
        #Get VM Information
        $ADUserInput = $VMItem.VMUser
        $ADUser = Get-ADUser -Identity $ADUserInput -Properties EmailAddress
        $VMType = $VMItem.VMType
 
        #Get VM Environment
        $VMEnvironment = $HOST.UI.RAWUI.WindowTitle

        if ($VSphereSession.Client.ServiceUrl -eq "https://SERVER.DOMAIN.local/sdk")
           {
            $VMEnvironment = "VA"
            $Host.ui.rawui.WindowTitle = "VMWare VA"
           }
        elseif ($VSphereSession.Client.ServiceUrl -eq "https://SERVER.DOMAIN.local/sdk") 
           {
            $VMEnvironment = "MN"
            $Host.ui.rawui.WindowTitle = "VMWare MN"    
           }
        else 
           {
               $VMEnvironment = $VMItem.VMEnvironment
           }

        if ($null -ne $ADUser)
        {
            #Create VM Name Based on AD User Account
            $ADUserName = $ADUser.Name.ToString()
            $VMName = $ADUserName
            $VMName = $VMName.Replace(".",'')
            $VMName = $VMName.Replace(" ","")
            
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
                    
                    #MN Template Variables
                    $VDIBaseTemplate = Get-Template VDI-Template-Base
                    $VDIOSCustomization = Get-OSCustomizationSpec "Windows 10 VDI"
                    $VDIVMHost = get-vmhost 'SERVER.DOMAIN.local'

                    #VDI Distribution Group Group
                    $VDIDistributionGroup = Get-ADGroup "GROUP"
                }
                "VA"
                {
                    $VIServer = "SERVER.DOMAIN.local"
                    $Horizon = 'SERVER.DOMAIN.local'
                    Write-Host "Duo Prompts Sent" -ForegroundColor Yellow -BackgroundColor Blue
                    Connect-VIServer $VIServer -Credential $adminCreds
                    Connect-HVServer $Horizon -Credential $adminCreds

                    #VA Template Variables
                    $VDIBaseTemplate = Get-Template VDI-Template-Base
                    $VDIOSCustomization = Get-OSCustomizationSpec "Windows 10 VDI"
                    $VDIVMHost = get-vmhost 'SERVER.DOMAIN.local'

                    #VDI Distribution Group
                    $VDIDistributionGroup = Get-ADGroup "GROUP"
                }
                else 
                {
                    Write-Error "Invalid Environment Selected" -RecommendedAction Break    
                }
            }
        
            #Set VM Name and Network Adapter
            Switch ($VMType)
            {
                "SVDI"
                {
                    $VMName = "SVDI$VMEnvironment-$VMName"
                    $VMNotes = ""
                    $NetworkAdapter = "ADAPTER"
                    $VMFolder = get-folder "FOLDER"
                    $PoolName = 'POOL'
                    $VDIDatastore = Get-DatastoreCluster "DATASTORE"
                    if ($VMEnvironment -eq "MN")
                    {
                        $ADGroup = "GROUP"
                    }
                    if ($VMEnvironment -eq "VA")
                    {
                        $ADGroup = "GROUP"
                    }
                }
                "PVDI"
                {
                    $VMName = "PVDI$VMEnvironment-$VMName"
                    $VMNotes = ""
                    $NetworkAdapter = "ADAPTER"
                    $VMFolder = Get-Folder "FOLDER"
                    $PoolName = 'POOLNAME'
                    $VDIDatastore = Get-Datastore 'DATASTORE'
                    if ($VMEnvironment -eq "MN")
                    {
                        $ADGroup = "GROUP"
                        #Adding to PVDI-Access for VDI Entitlements. This Will be Removed after Cutover
                        Add-ADGroupMember -Identity "GROUP" -Members $ADUserName
                    }
                    if ($VMEnvironment -eq "VA")
                    {
                        $ADGroup = "GROUP"
                        #Adding to PVDI-Access for VDI Entitlements. This Will be Removed after Cutover
                        Add-ADGroupMember -Identity "GROUP" -Members $ADUserName
                    }
                }
                
            }
            
            #Check if VM already exists
            $VMExistance = Get-VM $VMName -ErrorAction SilentlyContinue
            $ADExistance = Get-ADComputer ($VMName.Substring(0,14)) -ErrorAction SilentlyContinue

            #Start Cloning VM
            if ($null -eq $VMExistance -and $null -eq $ADExistance)
            {
                #Clone VM
                Write-Host "Cloning VM" -ForegroundColor Green
                Write-Host "New VM Name: $VMName" -ForegroundColor Magenta
                Write-Host "VM Folder: $VMFolder" -ForegroundColor Cyan
                Write-Host "VM Host: $VDIVMHost" -ForegroundColor Cyan
                Write-Host "VM Datastore: $VDIDatastore" -ForegroundColor Cyan
                Write-Host "VM Template:" $VDIBaseTemplate -ForegroundColor Cyan
                Write-Host "VM OS Customization: $VDIOSCustomization" -ForegroundColor Cyan
                Write-Host "VM Pool:" $PoolName -ForegroundColor Cyan
                New-VM -Name $VMName -Template $VDIBaseTemplate -Location $VMFolder -vmhost $VDIVMHost -datastore $VDIDatastore -OSCustomizationSpec $VDIOSCustomization -Notes $VMNotes
                $NewVDI = Get-VM $VMName
                Write-Host "Configuring Domain-Join Script" -ForegroundColor Green
                #New-AdvancedSetting -Name 'guestInfo.guestHostname' -Value $VMName -Entity $NewVDI -confirm:$false
                    
                #Set Network Adapter
                Write-Host 'Setting Network Adapter' -ForegroundColor Green
                Get-NetworkAdapter -VM $NewVDI | Set-NetworkAdapter -NetworkName $NetworkAdapter -Confirm:$false
                    
                #Add AD User to VDI Group and Proper Distribution Groups
                Write-Host "Adding $ADUserName to $ADGroup AD Group" -ForegroundColor Green
                Add-ADGroupMember -Identity $ADGroup -Members $ADUser.DistinguishedName -Verbose
                Add-ADGroupMember -Identity "SecureVDIUsers" -Members $ADUser.DistinguishedName -Verbose
                Write-Host "Adding $ADUserName to $VDIDistributionGroup" -ForegroundColor Green
                Add-ADGroupMember -Identity $VDIDistributionGroup.DistinguishedName -Members $ADUser.DistinguishedName -Verbose
                    
                #Add Assigned User to Secure VDI Pool
                Write-Host "Adding $NewVDI to $PoolName Pool" -ForegroundColor Green
                Add-HVDesktop -PoolName $PoolName -Machines $NewVDI -users "DOMAIN.local\$ADUserInput" -Vcenter $VIServer
                Write-Host "Assigning $ADUserInput to VDI" -ForegroundColor Green
                Start-Sleep -Seconds 15
                Set-HVMachine -MachineName $NewVDI -User "DOMAIN\$ADUserInput"
        
        
                Write-Host "$NewVDI has been created!" -ForegroundColor Green
                Get-HVMachineSummary -MachineName $NewVDI | Format-List

                if ($VMItem.Email.ToLower() -eq "yes")
                {
                #Send Email
                $FromAD = Get-Aduser $CurrentUser -Properties EmailAddress
                $FromADName = $FromAD.Name
                $FromADName = $FromADName.Replace("."," ")
                $FromADEmail = $FromAD.EmailAddress
                $Recipient = $ADUser.EmailAddress
                #$Recipient = $Recipient.Replace(".",'')
                $mailRelayServer = "smtp.DOMAIN.local"
                $EmailBody = "BODY"
                Write-Host "Sending Horizon Instructions to $Recipient" -ForegroundColor Green
                Send-MailMessage -To $Recipient -From $FromADEmail -Bcc $FromADEmail -Subject "Your new VDI has been created" -Body $EmailBody -BodyAsHtml -SmtpServer $mailRelayServer -Attachments '.\How to login to the VDI via VMware Horizon Client.docx' -Credential $adminCreds
                }

                #Add VMName to New VDI Array
                $NewVDIArray += $VMName
            }
            else   
            {
                Write-Host "$VMName already exists! Moving to next VM" -ForegroundColor Yellow -BackgroundColor Red
                Get-HVMachineSummary -MachineName $VMName | Format-List   
            } 
        }
        
            else 
            {
            Write-Host "$ADUserInput Useraccount does NOT Exist" -ForegroundColor Yellow -BackgroundColor Red
            }
        }
        
}
else 
{
    Write-Host "PowerCLI is not Installed!" -ForegroundColor Red
}