#https://www.azure365pro.com/office-365-mailbox-not-showing-in-hybrid-exchange-server/

#Get Credentials
$CurrentUser = $env:USERNAME
if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\a$CurrentUser"
}

#Connect to ActiveDirectory
$PSSession = Get-PSSession | Where-Object {$_.ComputerName -like "*ADDS*" -or $_.ComputerName -like "SERVER*"}
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
if ($null -eq (Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.exchange"}))
{
    $exchange = New-PSSession -ConfigurationName Microsoft.exchange -ConnectionUri http://SERVER/powershell -Credential $adminCreds
    Import-PSSession $exchange
    $host.ui.rawui.windowtitle="AD / Exchange"
}

$ADUserinput = Read-Host -Prompt "Enter AD Username"
$ADUser = Get-ADUser $ADUserinput -Properties msExchRemoteRecipientType,mailNickname,msExchProvisioningFlags,msExchModerationFlags,msExchAddressBookFlags,targetaddress,msExchRecipientDisplayType,msExchRecipientTypeDetails,emailaddress
if ($null -ne $ADuser)
{
    #Set AD Attributes
    Write-Host "Correcting $ADUserInput" -ForegroundColor Cyan
    $primarySMTPAddress = $ADUserinput+"@DOMAIN.com"
    $targetAddress = $ADUserinput+"@DOMAIN.onmicrosoft.com"
    $targetAddress = "SMTP:$targetAddress"
    $ADUserEmail = $ADUser.EmailAddress
    $PrimaryProxy = "SMTP:$ADUserEmail"
    $SecondaryProxy = "smtp:$ADUserinput@DOMAIN.mail.onmicrosoft.com"
    if ($null -eq $ADUser.targetaddress)
    {
        Write-Host "Setting $targetaddress as the Target Address" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Replace @{targetaddress="$targetAddress"}
        Set-ADUser $ADuser.Distinguishedname -Add @{ProxyAddresses=$PrimaryProxy}
        Set-ADUser $ADuser.Distinguishedname -Add @{ProxyAddresses=$SecondaryProxy}
    }
    if ($null -eq $ADUser.msExchRemoteRecipientType)
    {
        Write-Host "Correcting msExchRemoteRecipientType Attribute" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Add @{msExchRemoteRecipientType="4"}
    }
    if ($null -eq $ADUser.mailNickname)
    {
        Write-Host "Correcting mailNickname Attribute" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Add @{mailNickname="$ADUserInput"}
    }
    if ($null -eq $ADUser.msExchProvisioningFlags)
    {
        Write-Host "Correcting msExchProvisioningFlags Attribute" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Add @{msExchProvisioningFlags="0"}
    }
    if ($null -eq $ADUser.msExchModerationFlags)
    {
        Write-Host "Correcting msExchModerationFlags Attribute" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Add @{msExchModerationFlags="6"}
    }
    if ($null -eq $ADUser.msExchAddressBookFlags)
    {
        Write-Host "Correcting msExchAddressBookFlags Attribute" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Add @{msExchAddressBookFlags="1"}
    }
    if ($null -eq $ADUser.msExchRecipientDisplayType)
    {
        Write-Host "Correcting msExchRecipientDisplayType Attribute" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Replace @{msExchRecipientDisplayType="-2147483642"}
    }
    if ($null -eq $ADUser.msExchRecipientTypeDetails)
    {
        Write-Host "Correcting msExchRecipientTypeDetails Attribute" -ForegroundColor Green
        Set-ADUser $ADUser.DistinguishedName -Replace @{msExchRecipientTypeDetails="2147483648"}
    }


    #Set Remote Mailbox
    $RemoteMailbox = Get-RemoteMailbox $ADUserInput
    if ($null -ne $RemoteMailbox)
    {
        if ($RemoteMailbox.PrimarySMTPAddress -eq "")
        {
            Write-Host "Setting PrimarySMTPAddress" -ForegroundColor Green
            Set-RemoteMailbox $ADUserinput -PrimarySMTPAddress $primarySMTPAddress
            Get-RemoteMailbox $ADUserinput | Select-Object PrimarySMTPAddress
        }
        if ($null -eq $RemoteMailbox.RemoteRoutingAddress)
        {
            Write-Host "Setting Remote Routing Address" -ForegroundColor Green
            Set-RemoteMailbox $ADUserinput -RemoteRoutingAddress $SecondaryProxy
            Get-RemoteMailbox $ADUserinput | Select-Object RemoteRoutingAddress
        } 
    }

}

