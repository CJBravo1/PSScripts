#Mailbox Recon Script
#Written by Chris Jorenby

#Change Window Title
#$host.ui.RawUI.WindowTitle = "Mailbox Recon"
#Clear-Host
Write-Host "Exchange Recon" -ForegroundColor Green
Write-Host "Use this script to gather all Exchange resources"

$PSSession = Get-PSSession | Where-Object {$_.configurationName -like "*exchange"}

if ($null -eq $PSSession)
{
    $ExchServer = Read-Host "Enter Exchange Server"
    $ExchSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExchServer/powershell"
    Import-PSSession $ExchSession
}

#Get Exchange Domains
#$domains = Get-AcceptedDomain
$PrimaryDomain = Get-AcceptedDomain | Where-Object {$_.Default -eq $true}
Write-Host "Primary Domain $PrimaryDomain" -ForegroundColor Yellow

#Create Export Directory
$ExportDirectory = New-Item ".\$primaryDomain" -Type Directory

#Get Mailboxes
Write-Host "Gathering Mailboxes" -ForegroundColor Green
$mailboxes = get-Mailbox -ResultSize Unlimited
Write-Host "Creating Directories" -ForegroundColor Green
New-Item -Path $ExportDirectory -Name ReconMailboxes -ItemType Directory 
New-Item -Path $ExportDirectory -Name ReconGroups -ItemType Directory
New-Item -Path "$ExportDirectory\ReconGroups" -Name ReconGroupMembers -ItemType Directory
foreach ($mailbox in $Mailboxes)
{
    $Mailboxstatistics = Get-Mailbox $mailbox.Identity | Get-MailboxStatistics
    $Table = [PSCustomObject]@{
        DisplayName =$mailbox.DisplayName
        Name = $mailbox.Name
        Alias = $mailbox.Alias
        #samaccountname = $mailbox.samaccountname
        database = $mailbox.Database.name
        primarysmtpaddress = $mailbox.primarysmtpaddress
        userprincipalname = $mailbox.userprincipalname
        RecipientTypeDetails = $mailbox.RecipientTypeDetails
        GrantSendOnBehalfTo = $mailbox.GrantSendOnBehalfTo.Name
        ForwardingAddress = $mailbox.ForwardingAddress
        ForwardingSMTPAddress = $mailbox.ForwardingSmtpAddress
        MailboxSize = $Mailboxstatistics.TotalItemSize.Value
        EmailAddresses = $mailbox.EmailAddresses
    }
    #Export to CSV files
    $Table | Export-Csv "$ExportDirectory\ReconMailboxes\AllMailboxes.csv" -NoTypeInformation -Append

    #Gather Mailbox Permissions
    $members = get-Mailboxpermission -Identity $mailbox.Alias | Where-Object {$_.User -like "*@*.com" -or $_.User -like "*\*" -and $_.User -notlike "NT AUTHORITY\*"}
    foreach ($member in $members)
    {
        $AccessRights = $members.AccessRights | Out-String
        $Table = [PSCustomObject]@{
            Identity = $member.Identity
            User = $member.User
            MailboxType = $mailbox.RecipientTypeDetails
            AccessRights = $AccessRights
            }
    $Table | Export-Csv -NoTypeInformation "$ExportDirectory\ReconMailboxes\MailboxPermissions.csv" -Append
    }
}

#Get Distribution Groups
Write-Host "Gathering Distribution Groups" -ForegroundColor Green
$distroGroups = Get-DistributionGroup -ResultSize unlimited
$distroGroups | Select-Object name,displayname,alias,primarysmtpaddress,EmailAddresses | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\DistributionGroups.csv"
Write-Host "Processing Group Memberships" -ForegroundColor Yellow
foreach ($group in $distroGroups)
{
    $groupName = $group.Name
    #Write-Host "Processing $groupName" -ForegroundColor Green
    $groupMembers = Get-DistributionGroupMember -Identity "$group"
    $groupMembers | Select-Object Name,Displayname,UserPrincipalname,primarySMTPAddress | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\ReconGroupMembers\$groupName.csv"
}

#Get Dynamic Distribution Groups
New-Item -Path "$ExportDirectory\ReconGroups\DynamicDistributionGroupMembers" -Name ReconGroupMembers -ItemType Directory
Write-Host "Gathering Dynamic Distribution Groups" -ForegroundColor Green
$ddGroup = Get-DynamicDistributionGroup -Resultsize Unlimited

#Get Group Members and Export as separate CSV Files
foreach ($group in $ddGroup) 
    {
    $groupAlias = $group.Alias
    Write-Host "Processing $groupAlias" -ForegroundColor Yellow
    Get-Recipient -RecipientPreviewFilter $group.RecipientFilter -OrganizationalUnit $group.RecipientContainer | Select-Object Name,DisplayName,Alias,Identity,Company,Office,PrimarySMTPAddress,UserPrincipalName,AcceptMessagesOnlyFromSendersOrMembers  | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\DynamicDistributionGroupMembers\$groupAlias.csv"
    }

#Gather Public Folders
Write-Host "Gathering Public Folders" -ForegroundColor Magenta
$publicFolders = get-PublicFolder -Recurse -ErrorAction SilentlyContinue
if ($null -eq $publicFolders)
{
    Write-Host "No Public Folders Were Found!" -ForegroundColor Red
}

else 
{
    New-Item -Path $ExportDirectory -Name "PublicFolders" -ItemType Directory
    $publicFolders | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\PublicFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Contact"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\ContactFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Note"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\NoteFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Appointment"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\CalendarFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Journal"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\JournalFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.StickyNote"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\StikcyNotes.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Task"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\TasksFolder.csv"
}

#Gather Server Information
Write-Host "Gathering Exchange Servers" -ForegroundColor Green 
$ExchangeServers = Get-ExchangeServer 
$ExchangeServers | Select-Object Name, Edition, AdminDisplayVersion, ServerRole, OperatingSystem, ExchangeVersion, IsHubTransportServer, IsClientAccessServer, IsEdgeServer, IsMailboxServer | Export-Csv -NoTypeInformation "$ExportDirectory\ExchangeServers.csv"

foreach ($Server in $ExchangeServers)
{
    # Get internal and external URLs
    $ECPVirtualDirectory = Get-ECPVirtualDirectory -Server $Server 
    $OWAVirtualDirectory = Get-OWAVirtualDirectory -Server $Server 
    
    #Servers and Certificates
    $Certificates = Get-ExchangeCertificate -Server $Server
    $PrimaryCertificate = $Certificates | Where-Object {$_.CertificateDomains -like $PrimaryDomain.Name -and $_.Status -eq "Valid"}

    $Results = [PSCustomObject]@{
        Server = $Server.Name
        Domain = $Server.Domain
        FQDN = $Server.FQDN
        OperatingSystem = $Server.OperatingSystem
        Edition = $Server.Edition
        ExchangeVersion = $Server.AdminDisplayVersion
        Roles = $server.ServerRole.toString()
        ECPInternalURL = $ECPVirtualDirectory.InternalUrl
        ECPExternalURL = $ECPVirtualDirectory.ExternalUrl
        OWAInternalURL = $OWAVirtualDirectory.InternalUrl
        OWAExternalURL = $OWAVirtualDirectory.ExternalUrl
        OWADefaultDomain = $OWAVirtualDirectory.DefaultDomain
        CertificateDomains = $PrimaryCertificate.CertificateDomains.Address -join ', '
        CertificateIssuer = $PrimaryCertificate.Issuer
        CertificateSubject = $PrimaryCertificate.Subject
        CertificateStatus = $PrimaryCertificate.Status
        CertificateStartDate = $PrimaryCertificate.NotBefore
        CertificateEndDate = $PrimaryCertificate.NotAfter
        CertificateServices =  $PrimaryCertificate.Services
        CertificateKeySize = $PrimaryCertificate.PublicKeySize
    }
    $Results | Export-Csv -NoTypeInformation "$ExportDirectory\ServersandCertificates.csv" -Append
}
# Get the list of send and receive connectors
Write-Host "Gathering Send Connectors" -ForegroundColor Green
$SendConnectors = Get-SendConnector 
foreach ($Connector in $SendConnectors)
{
    $Results = [PSCustomObject]@{
        Identity = $Connector.Identity
        Name = $Connector.Name
        Enabled = $Connector.Enabled
        DnsRoutingEnabled = $Connector.DnsRoutingEnabled
        SmartHosts = $Connector.SmartHosts
        AddressSpaceAddress = $Connector.AddressSpaces.Address
        AddressSpaceType = $Connector.Address.Type
        SourceIP = $connector.SourceIPAddress.IPAddressToString
        SourceTransportServers = $connector.SourceTransportServers.name
        TlsDomainAddress = $connector.TlsDomain.Address
        TLSDomainDomain = $connector.TlsDomain.domain
        TLSCertificateName = $connector.TlsCertificateName.CertificateSubject
        TLSCertificateIssuer = $connector.TlsCertificateName.CertificateIssuer
    }
    $Results | Export-Csv -NoTypeInformation "$ExportDirectory\SendConnectors.csv" -Append
}

$ReceiveConnectors = Get-ReceiveConnector
Write-Host "Gathering Receive Connectors" -ForegroundColor Green
foreach ($Connector in $ReceiveConnectors)
{
    $Results = [PSCustomObject]@{
        Identity = $Connector.Identity
        Name = $Connector.Name
        Enabled = $Connector.Enabled
        Server = $Connector.Server
        TransportRole = $Connector.TransportRole
        FQDN = $connector.FQDN.domain
        BindingsAddressFamilyIPv4 = ($Connector.Bindings| Where-Object {$_.Addressfamily -eq "InterNetwork"}).Addressfamily
        BindingsAddressIPv4 = ($Connector.Bindings| Where-Object {$_.Addressfamily -eq "InterNetwork"}).Address.IPAddressToString
        BindingsPortIPv4 = ($Connector.Bindings| Where-Object {$_.Addressfamily -eq "InterNetwork"}).Port 
    }
    $Results | Export-Csv -NoTypeInformation "$ExportDirectory\ReceiveConnectors.csv" -Append
}

Write-Host "End of Recon" -ForegroundColor Green -BackgroundColor Blue