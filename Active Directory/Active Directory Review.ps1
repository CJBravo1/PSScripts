# Define output file paths
$AdminGroupMembershipCSV = ".\AdminGroupMemberships.csv"
$DcDiagFile = ".\AD_DCDiag_Report.txt"
$outputFile = ".\AD_Review_Report.txt"


# Function to write content to the report file
function Write-ReportContent {
    param (
        [string]$content
    )
    Add-Content -Path $outputFile -Value $content
}

#Get a list of ALL domain controllers
$ADDomainControllers = Get-ADDomainController -Filter *

Write-ReportContent "Active Directory Domain controllers, Operating System, and Roles"
$ADDomainControllers | Select-Object Name,OperatingSystem,OperationMasterRoles > $outputFile

# Run replication testing and review DCDiag/Repadmin results
Write-Host "Testing Active Directory Replication" -ForegroundColor Green 
#dcdiag /e /c /v >> $DcDiagFile





# Review Directory Service for any stale AD objects
Write-ReportContent "Review for Stale AD Objects:"
Write-ReportContent "-------------------------------"
$staleThreshold = (Get-Date).AddDays(-90)

# Get all user accounts that haven't logged in for a specified period
$staleUsers = Get-ADUser -Filter {
    (LastLogonDate -lt $staleThreshold) -and (Enabled -eq $true)
} -Properties LastLogonDate | Select-Object Name, SamAccountName, LastLogonDate | sort LastLogonDate

# Display or export the list of stale user accounts
if ($staleUsers) {
    Write-Host "Stale User Accounts:"
    $staleUsers | Format-Table -AutoSize
    $staleUsers | Format-Table -AutoSize >> $outputFile

} else {
    Write-Host "No stale user accounts found." -ForegroundColor Green
}

# Get all computer objects that haven't logged in for a specified period
$staleComputers = Get-ADComputer -Filter {
    (LastLogonDate -lt $staleThreshold) -and (Enabled -eq $true)
} -Properties LastLogonDate | Select-Object Name, SamAccountName, LastLogonDate | sort LastLogonDate
# Display or export the list of stale user accounts
if ($staleComputers) {
    Write-Host "Stale Computer Accounts:"
    $staleComputers | Format-Table -AutoSize
    $staleComputers | Format-Table -AutoSize >> $outputFile
} else {
    Write-Host "No stale computer accounts found." -ForegroundColor Green
}


# Check AD Sites and services and review for stale DC servers
Write-Host "Reviewing Sites and Services" -foregroundColor Green
Write-ReportContent "AD Sites and Services:"
Write-ReportContent "-----------------------"
# Get all Active Directory Sites
# Get all Active Directory Sites
$sites = Get-ADReplicationSite -Filter *

# Iterate through each site
foreach ($site in $sites) {
    Write-Host "Site: $($site.Name)"

    # Get all servers in the current site
    $serversInSite = Get-ADDomainController -Filter {Site -eq $site.Name} 

    if ($serversInSite.Count -eq 0) {
        Write-Host "No servers found in this site."
    } else {
        Write-Host "Servers in this site:"
        $serversInSite | Format-Table Name, IPv4Address -AutoSize

        # List replication partners within the same site
        Write-ReportContent "Replication within this site:"
        foreach ($server in $serversInSite) {
            $partners = Get-ADReplicationPartnerMetadata -Target $server
            foreach ($partner in $partners) {
                if ($partner.Partner -ne $server.Name) {
                    Write-ReportContent "$($server.Name) is replicating to $($partner.Partner)"
                }
            }
        }
    }   

}

Write-ReportContent "$replicationConnections"

# Review default domain GPO configuration and note secondary GPOs
Write-ReportContent "GPO Configuration:"
Write-ReportContent "------------------"
# You can add your code to review GPO configuration and append the results to the report file
Write-ReportContent ""

# Review security rights, roles, and domain administrator permissions
Write-ReportContent "Security Rights, Roles, and Permissions:"
Write-ReportContent "---------------------------------------"

$AdminGroups = Get-ADGroup -Filter {Name -like "*Admins"} 
foreach ($adminGroup in $adminGroups) {
    # Get the members of the current Administrative Group
    $groupMembers = Get-ADGroupMember -Identity $adminGroup.Name #| Select-Object Name, SamAccountName, ObjectClass
    $AdminGroupMembership = foreach ($member in $groupMembers) {
        # Create an object to store the data
        [PSCustomObject] @{
            "Admin Group Name" = $adminGroup.Name
            "Admin Group Member" = $member.Name
            "Admin Group Member Type" = $member.objectClass
        }

    # Add the object to the results array
$AdminGroupMembership| Export-Csv -NoTypeInformation $AdminGroupMembershipCSV -Append
}
#$AdminGroupMembership 
}
# Review DNS synchronization
Write-ReportContent "DNS Synchronization:"
Write-ReportContent "---------------------"
# You can add your code to check DNS synchronization and append the results to the report file
Write-ReportContent ""

# Display a message indicating that the report has been generated
Write-Host "Active Directory review report has been generated at $outputFile" -ForegroundColor Green
Write-Host "dcdiag testing is outputed to $DcDiagFile" -ForegroundColor Green
Write-Host "Admin Group Memberships outputed to $AdminGroupMembershipCSV" -ForegroundColor Green