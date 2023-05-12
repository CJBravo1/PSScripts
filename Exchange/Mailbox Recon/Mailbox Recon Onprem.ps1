#Mailbox Recon Script
#Written by Chris Jorenby

#Change Window Title
#$host.ui.RawUI.WindowTitle = "Mailbox Recon"
#Clear-Host
Write-Host "Mailbox Recon" -ForegroundColor Green
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

#Create Export Directory
$ExportDirectory = New-Item ".\$primaryDomain" -Type Directory

#Get Mailboxes
Write-Host "Gathering Mailboxes" -ForegroundColor Cyan
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
        primarysmtpaddress = $mailbox.primarysmtpaddress
        userprincipalname = $mailbox.userprincipalname
        RecipientTypeDetails = $mailbox.RecipientTypeDetails
        GrantSendOnBehalfTo = $mailbox.GrantSendOnBehalfTo
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
Write-Host "Gathering Distribution Groups" -ForegroundColor Cyan
New-Item -Path .\ -Name ReconGroups -ItemType Directory > $null
New-Item -Path .\ReconGroups -Name ReconGroupMembers -ItemType Directory > $null
$distroGroups = Get-DistributionGroup -ResultSize unlimited
$distroGroups | Select-Object name,displayname,alias,primarysmtpaddress,EmailAddresses | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\DistributionGroups.csv"
Write-Host "Processing Group Memberships" -ForegroundColor Yellow
foreach ($group in $distroGroups)
{
    $groupName = $group.Name
    #Write-Host "Processing $groupName" -ForegroundColor Cyan
    $groupMembers = Get-DistributionGroupMember -Identity "$group"
    $groupMembers | Select-Object Name,Displayname,UserPrincipalname,primarySMTPAddress | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\ReconGroupMembers\$groupName.csv"
}

#Get Dynamic Distribution Groups
mkdir .\ReconGroups\DynamicDistributionGroupMembers > $null
Write-Host "Gathering Dynamic Distribution Groups" -ForegroundColor Cyan
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
$publicFolders = get-PublicFolder -Recurse
if ($null -eq $publicFolders)
{
    Write-Host "No Public Folders Were Found!" -ForegroundColor Red
}

else 
{
    mkdir .\PublicFolders
    $publicFolders | Export-Csv -NoTypeInformation.PublicFolders\PublicFolders.csv
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Contact"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\ContactFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Note"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\NoteFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Appointment"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\CalendarFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Journal"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\JournalFolders.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.StickyNote"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\StikcyNotes.csv"
    $publicFolders | Where-Object {$_.folderType -eq "IPF.Task"} | Export-Csv -NoTypeInformation "$ExportDirectory\PublicFolders\TasksFolder.csv"
}

#Gather Server Information
$ExchangeServers = Get-ExchangeServer 
$ExchangeServers | Select-Object Name, Edition, AdminDisplayVersion, ServerRole, OperatingSystem, ExchangeVersion, IsHubTransportServer, IsClientAccessServer, IsEdgeServer, IsMailboxServer, AdminDisplayVersion | Export-Csv -NoTypeInformation "$ExportDirectory\ExchangeServers.csv"

foreach ($Server in $ExchangeServers)
{
    # Get internal and external URLs
    $ECPVirtualDirectory = Get-ECPVirtualDirectory -Server $Server 
    $OWAVirtualDirectory = Get-OWAVirtualDirectory -Server $Server 
    
    $Results = @{
        Server = $Server.Name
        Domain = $Server.Domain
        OperatingSystem = $Server.OperatingSystem
        Edition = $Server.Edition
        ExchangeVersion = $Server.AdminDisplayVersion
        Roles = $server.Roles
        ECPInternalURL = $ECPVirtualDirectory.InternalUrl
        ECPExternalURL = $ECPVirtualDirectory.ExternalUrl
        OWAInternalURL = $OWAVirtualDirectory.InternalUrl
        OWAExternalURL = $OWAVirtualDirectory.ExternalUrl
        DefaultDomain = $OWAVirtualDirectory.DefaultDomain
    }
    $Results | Export-Csv -NoTypeInformation "$ExportDirectory\Serverinfo.csv"
}

Get-ExchangeCertificate -Server $server  | Export-Csv -NoTypeInformation "$ExportDirectory\Certificates.csv"

# Get the list of send and receive connectors
Get-SendConnector | Select-Object Identity, Name, Enabled, DnsRoutingEnabled, SmartHosts, AddressSpaces, SourceTransportServers, TlsDomain, MaxMessageSize, PermissionGroups | Export-Csv -NoTypeInformation "$ExportDirectory\SendConnectors.csv" 
Get-ReceiveConnector | Select-Object Identity, Name, Enabled, Bindings, PermissionGroups, RemoteIPRanges, TlsCertificateName, MaxMessageSize, ProtocolLoggingLevel | Export-Csv -NoTypeInformation "$ExportDirectory\ReceiveConnectors.csv"


Write-Host "End of Recon" -ForegroundColor Green -BackgroundColor Blue