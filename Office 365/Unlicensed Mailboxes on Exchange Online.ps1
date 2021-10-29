
#Requires -Modules Msonline
Set-StrictMode -Version Latest

#Connect to Exchange / Office 365

$msolcred = Get-Credential -Message "Enter Office 365 Admin Password"

#PSSessions
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $msolcred -Authentication Basic -AllowRedirection
$ComplianceSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $MSOLcred -Authentication Basic -AllowRedirection
$protectionsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.protection.outlook.com/powershell-liveid/ -Credential $msolcred -Authentication Basic -AllowRedirection

#Connect to Office 365 environment
#Write-Host "Connecting to Azure Active Directory" -ForegroundColor Magenta
Connect-MsolService -Credential $msolcred -WarningAction SilentlyContinue

#Import PSSessions
#Write-Host "Connecting to Exchange" -ForegroundColor Cyan
Import-PSSession $ExchangeSession -DisableNameChecking -WarningAction SilentlyContinue | out-null
Import-PSSession $ComplianceSession -DisableNameChecking -WarningAction SilentlyContinue | out-null
#Import-PSSession $protectionsession -DisableNameChecking -WarningAction SilentlyContinue | out-null
$domainInfo = Get-WMIObject Win32_NTDomain
$domainInfo = Get-WMIObject Win32_NTDomain
$domainInfo = Get-WMIObject Win32_NTDomain 


#Check if MSOLService is connected

 
try
{
    Get-MsolDomain -ErrorAction Stop | Out-Null
}
catch 
{
    Write-Error "The MSOLService is not connected, please run Connect-MSOLService and try again"
    Exit
}
 
 
#Find the Remote session that is currently active. If for some reasons the session broke inbetween the script, user needs to fix it and re-run the script
$RemoteSession = Get-PSSession | Where-Object{$_.state -eq 'opened' -and $_.configurationname -eq 'Microsoft.Exchange' -and $_.ComputerName -eq 'outlook.office365.com' } | Select-Object -First 1
If(-not $RemoteSession){
    Write-Error "Unable to find the session configuration, please reconnect to Exchange online powershell session and try again. "
    Exit
}
 
#Check if the Outputfile exists, if yes just rename and continue
[STRING]$Outfile = "C:\Temp\UnlicensedMbxs_$(Get-Date -format "yyyyMMdd").CSV"
if(Test-Path $Outfile){
    Rename-Item $Outfile "$Outfile.old"
 
}
 
#LicenseReconciliationNeededOnly - indicates whether an additional license assignment is required to bring the user into compliance
#Lets just collect all of them
$ReconciliationUsers = Get-MsolUser -All -LicenseReconciliationNeededOnly | Select-Object UserPrincipalName, IsLicensed, LicenseReconciliationNeeded, Licenses
 
$Params = @{UserPrincipalName=[STRING];MailboxCreatedON=[DateTime];IsLicensed=[BOOL]$false;LicenseReconciliationNeeded=[BOOL]$false;DaysUnlicensed=[INT]-1;HasAnyExcLicense=[BOOL]$False}
 
#We are interested only on Unlicensed mailboxes, If the MailboxCreatedON is blank, there is no mailbox provisioned for this user on Online.
#The script outputs everything in to the CSV file, Users can filter on MailboxCreatedON field for filtering Unlicensed mailboxes.
 
Foreach($User in $ReconciliationUsers){
    #Create the Custom object to store the results
    $UserObj = New-Object -TypeName PSCustomObject -Property $Params
 
    $UserObj.UserPrincipalName = $user.UserPrincipalName
    $UserObj.IsLicensed = $user.IsLicensed
    $UserObj.LicenseReconciliationNeeded = $user.LicenseReconciliationNeeded
    $Userobj.MailboxCreatedON = Get-Mailbox $User.UserPrincipalName -ErrorAction silentlycontinue | Select-Object -ExpandProperty WhenMailboxCreated 
    #If user has mailbox, check how many days it is there unlicensed
    if($UserObj.MailboxCreatedON){
        $UserObj.DaysUnlicensed = ((Get-Date) - $UserObj.MailboxCreatedON).Days
    }
    #Check if there is any Exchange license assgined for this user, if yes, Include it in report
    if( @($user.Licenses).count){
        if($User.Licenses[0].ServiceStatus | Where-Object {$_.serviceplan.servicetype -eq 'Exchange' -and $_.ProvisioningStatus -eq 'Success'}){
            $UserObj.HasAnyExcLicense = $true
        }
    }
    #Append the output to the file as the script collects it
    $UserObj | Export-Csv $Outfile -Append -NoTypeInformation
}

pause