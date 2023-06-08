#Mailbox Recon Script
#Written by Chris Jorenby

#Check for Current Exchange PSSession
$PSSession = Get-AcceptedDomain

if ($null -eq $PSSession)
    {
    #Make new session
    Write-Host "Connect to Exchange Online" -ForegroundColor Yellow
    #Connect-ExchangeOnline 
    }
        # Export Primary Domains
        $PrimaryDomain = Get-AcceptedDomain | Where-Object {$_.default -eq $true}
        Write-Host "Primary Domain: $PrimaryDomain" -ForegroundColor Yellow
        Write-Host "Exporting Accepted Domains" -ForegroundColor Green
        $domains = Get-AcceptedDomain
        $domains | Export-Csv -NoTypeInformation "$ExportDirectory\AcceptedDomains.csv"

    function Export-MailboxReconData {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ExportDirectory,
            
            [Parameter(Mandatory = $true)]
            [string]$PrimaryDomain
        )
        
        # Get Mailboxes
        Write-Host "Gathering Mailboxes" -ForegroundColor Green
        $Mailboxes = Get-EXOMailbox -ResultSize Unlimited
    
        # Export All Mailboxes
        $reconMailboxesDir = New-Item -Path $ExportDirectory -Name "ReconMailboxes" -ItemType Directory
        $totalMailboxes = $Mailboxes.Count
        $progress = 0
        foreach ($mailbox in $Mailboxes) {
            $progress++
            Write-Progress -Activity "Exporting Mailboxes" -Status "Progress: $progress / $totalMailboxes" -PercentComplete (($progress / $totalMailboxes) * 100)
            
            $mailboxStatistics = Get-MailboxStatistics -Identity $mailbox.PrimarySMTPAddress
            $table = [PSCustomObject]@{
                DisplayName = $mailbox.DisplayName
                Name = $mailbox.Name
                Alias = $mailbox.Alias
                PrimarySMTPAddress = $mailbox.PrimarySmtpAddress
                UserPrincipalName = $mailbox.UserPrincipalName
                RecipientTypeDetails = $mailbox.RecipientTypeDetails
                GrantSendOnBehalfTo = $mailbox.GrantSendOnBehalfTo
                ForwardingAddress = $mailbox.ForwardingAddress
                ForwardingSMTPAddress = $mailbox.ForwardingSmtpAddress
                MailboxSize = $mailboxStatistics.TotalItemSize.Value
                EmailAddresses = $mailbox.EmailAddresses
            }
            # Export to CSV file
            $table | Export-Csv -NoTypeInformation "$reconMailboxesDir\AllMailboxes.csv" -Append
    
            # Gather Mailbox Permissions
            $members = Get-MailboxPermission -Identity $mailbox.Alias | Where-Object { $_.User -like "*@*.com" -or $_.User -like "*\*" -and $_.User -notlike "NT AUTHORITY\*" }
            foreach ($member in $members) {
                $accessRights = $members.AccessRights | Out-String
                $table = [PSCustomObject]@{
                    Identity = $member.Identity
                    User = $member.User
                    MailboxType = $mailbox.RecipientTypeDetails
                    AccessRights = $accessRights
                }
                $table | Export-Csv -NoTypeInformation "$reconMailboxesDir\MailboxPermissions.csv" -Append
            }
        }
    }
    
    function Export-DistributionGroups {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ExportDirectory
        )
    
        # Get Distribution Groups
        Write-Host "Gathering Distribution Groups" -ForegroundColor Green
        $reconGroupExportDir = New-Item -Path $ExportDirectory -Name "ReconGroups" -ItemType Directory
        $reconGroupMembersExportDir = New-Item -Path $reconGroupExportDir -Name "ReconGroupMembers" -ItemType Directory
        $distroGroups = Get-DistributionGroup -ResultSize unlimited
        $distroGroups | Select-Object name,displayname,alias,primarysmtpaddress,EmailAddresses | Export-Csv -NoTypeInformation "$reconGroupExportDir\DistributionGroups.csv"
        $totalGroups = $distroGroups.Count
        $progress = 0
        foreach ($group in $distroGroups) {
            $progress++
            Write-Progress -Activity "Exporting Distribution Groups" -Status "Progress: $progress / $totalGroups" -PercentComplete (($progress / $totalGroups) * 100)
            
            $groupName = $group.Alias
            $groupMembers = Get-DistributionGroupMember -Identity $group.PrimarySmtpAddress
            $groupMembers | Export-Csv -NoTypeInformation "$reconGroupMembersExportDir\$groupName.csv"
        }
    }
    
    function Export-DynamicDistributionGroups {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ExportDirectory
        )
    
        # Get Dynamic Distribution Groups
        $reconDynamicGroupExportDir = New-Item -Path $ExportDirectory -Name "DynamicDistributionGroupMembers" -ItemType Directory
        Write-Host "Gathering Dynamic Distribution Groups" -ForegroundColor Green
        $ddGroups = Get-DynamicDistributionGroup -ResultSize Unlimited -ErrorAction SilentlyContinue
        $totalGroups = $ddGroups.Count
        $progress = 0
        foreach ($group in $ddGroups) {
            $progress++
            Write-Progress -Activity "Exporting Dynamic Distribution Groups" -Status "Progress: $progress / $totalGroups" -PercentComplete (($progress / $totalGroups) * 100)
            
            $groupAlias = $group.Alias
            Write-Host "Processing $groupAlias" -ForegroundColor Yellow
            Get-Recipient -RecipientPreviewFilter $group.RecipientFilter -OrganizationalUnit $group.RecipientContainer | Select-Object Name, DisplayName, Alias, Identity, Company, Office, PrimarySmtpAddress, UserPrincipalName, AcceptMessagesOnlyFromSendersOrMembers | Export-Csv -NoTypeInformation "$reconDynamicGroupExportDir\$groupAlias.csv"
        }
    }
    
    function Export-Office365Groups {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ExportDirectory
        )
    
        # Get Office 365 Groups
        Write-Host "Gathering Office 365 Groups" -ForegroundColor Green
        $unifiedGroups = Get-UnifiedGroup -ResultSize Unlimited
        $totalGroups = $unifiedGroups.Count
        $progress = 0
        $csvTable = foreach ($group in $unifiedGroups) {
            $progress++
            Write-Progress -Activity "Exporting Office 365 Groups" -Status "Progress: $progress / $totalGroups" -PercentComplete (($progress / $totalGroups) * 100)
            
            # Get Group Members
            $members = Get-UnifiedGroupLinks -LinkType Member -Identity $group.PrimarySmtpAddress
    
            foreach ($member in $members) {
                [PSCustomObject]@{
                    GroupName = $group.DisplayName
                    GroupEmail = $group.PrimarySmtpAddress
                    MemberName = $member.Name
                    MemberEmail = $member.PrimarySmtpAddress
                }
            }
        }
    
        # Export Table to CSV File
        Write-Host "Exporting Data to Office365Groups.csv" -ForegroundColor Green
        $csvTable | Export-Csv -NoTypeInformation "$ExportDirectory\ReconGroups\Office365Groups.csv"
    }
    
    function Export-PublicFolders {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ExportDirectory
        )
    
        # Get Public Folders
        Write-Host "Gathering Public Folders" -ForegroundColor Green
        $publicFolders = Get-PublicFolder -Recurse -ErrorAction SilentlyContinue
        $totalFolders = $publicFolders.Count
        $progress = 0
        
        if ($publicFolders) {
            $publicFoldersDir = New-Item -Path $ExportDirectory -Name "PublicFolders" -ItemType Directory
            $publicFolders | Export-Csv -NoTypeInformation "$publicFoldersDir\PublicFolders.csv"
            
            foreach ($folder in $publicFolders) {
                $progress++
                Write-Progress -Activity "Exporting Public Folders" -Status "Progress: $progress / $totalFolders" -PercentComplete (($progress / $totalFolders) * 100)
                
                $folderType = $folder.FolderType
                $folderTypeDir = "$publicFoldersDir\$folderType"
                
                if (!(Test-Path $folderTypeDir)) {
                    New-Item -Path $publicFoldersDir -Name $folderType -ItemType Directory | Out-Null
                }
                
                $folder | Export-Csv -NoTypeInformation "$folderTypeDir\$($folder.Name).csv"
            }
        } else {
            Write-Host "No Public Folders Were Found!" -ForegroundColor Red
        }
    }
    
    function Export-InboundConnectors {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ExportDirectory
        )
    
        # Get Inbound Connectors
        Write-Host "Gathering Inbound Connectors" -ForegroundColor Green
        $inboundConnectors = Get-InboundConnector
        #$totalConnectors = $inboundConnectors.Count
        $progress = 0
        $results = foreach ($connector in $inboundConnectors) {
            $progress++
            #Write-Progress -Activity "Exporting Inbound Connectors" -Status "Progress: $progress / $totalConnectors" -PercentComplete (($progress / $totalConnectors) * 100)
            
            [PSCustomObject]@{
                Identity = $connector.Identity
                Name = $connector.Name
                Enabled = $connector.Enabled
                ConnectorType = $connector.ConnectorType
                AssociatedAcceptedDomains = $connector.AssociatedAcceptedDomains
                RequireTls = $connector.RequireTls
                TlsSenderCertificateName = $connector.TlsSenderCertificateName
                RestrictDomainsToIPAddresses = $connector.RestrictDomainsToIPAddresses
                RestrictDomainsToCertificate = $connector.RestrictDomainsToCertificate
                SenderDomains = $connector.SenderDomains -join '; '
                SenderIPAddresses = $connector.SenderIPAddresses -join ', '
            }
        }
        $results | Export-Csv -NoTypeInformation "$ExportDirectory\InboundConnectors.csv"
    }
    
    function Export-OutboundConnectors {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ExportDirectory
        )
    
        # Get Outbound Connectors
        Write-Host "Gathering Outbound Connectors" -ForegroundColor Green
        $outboundConnectors = Get-OutboundConnector -IncludeTestModeConnectors $true
        #$totalConnectors = $outboundConnectors.Count
        $progress = 0
        $results = foreach ($connector in $outboundConnectors) {
            $progress++
            #Write-Progress -Activity "Exporting Outbound Connectors" -Status "Progress: $progress / $totalConnectors" -PercentComplete (($progress / $totalConnectors) * 100)
            
            [PSCustomObject]@{
                Identity = $connector.Identity
                Name = $connector.Name
                Enabled = $connector.Enabled
                ConnectorType = $connector.ConnectorType
                SmartHosts = $connector.SmartHosts
                TlsDomain = $connector.TlsDomain
                TlsSettings = $connector.TlsSettings
                AllAcceptedDomains = $connector.AllAcceptedDomains
            }
        }
        $results | Export-Csv -NoTypeInformation "$ExportDirectory\OutboundConnectors.csv"
    }
    
    #Welcome Prompt
    Write-Host "Exchange Online Recon" -ForegroundColor Green
    Write-Host "Use this script to gather all Microsoft Exchange Online Resources" -ForegroundColor Yellow
    
    # Check for Current Exchange PSSession
    if (!(Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" })) {
        #Connect-ExchangeOnline
    }
    
    # Create Export Directory
    $exportDirectory = Join-Path -Path .\ -ChildPath $primaryDomain
    New-Item -Path $exportDirectory -Type Directory | Out-Null
    
    Export-MailboxReconData -ExportDirectory $exportDirectory -PrimaryDomain $primaryDomain
    Export-DistributionGroups -ExportDirectory $exportDirectory
    Export-DynamicDistributionGroups -ExportDirectory $exportDirectory
    Export-Office365Groups -ExportDirectory $exportDirectory
    Export-PublicFolders -ExportDirectory $exportDirectory
    Export-InboundConnectors -ExportDirectory $exportDirectory
    Export-OutboundConnectors -ExportDirectory $exportDirectory
    
    Write-Host "End of Recon" -ForegroundColor Green
    Write-Host "Export Directory: $exportDirectory" -ForegroundColor Yellow