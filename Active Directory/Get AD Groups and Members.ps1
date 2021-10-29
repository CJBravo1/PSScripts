#Import Active Directory
Import-Module ActiveDirectory

$ADGroups = Get-ADGroup -filter * 

#Create Blank Table
$CSVTable = @()
 


foreach ($group in $ADGroups)
    {
        $CSVLine = New-Object psobject  
        $GroupName = $group.Name
        $GroupDN = $group.DistinguishedName
        $GroupSAM = $group.SamAccountName
        $GroupMembers = Get-AdGroupMember -Identity $group
        
        #Add Group Information to Table
        $CSVLine | Add-Member -NotePropertyName "GroupName" -NotePropertyValue $GroupName
        $CSVLine | Add-Member -NotePropertyName "GroupDN" -NotePropertyValue $GroupDN
        $CSVLine | Add-Member -NotePropertyName "GroupSAMAccountName" -NotePropertyValue $GroupSAM
        foreach ($member in $GroupMembers)
        {
            $memberName = $member.DisplayName
            $memberSAM = $member.SamAccountName
            $memberUPN = $member.UserPrincipalName
            
            #Add User Information To Table
            $CSVLine | Add-Member -NotePropertyName "UserDisplayName" -NotePropertyValue $memberName
            $CSVLine | Add-Member -NotePropertyName "MemberSAMAccoutnName" -NotePropertyValue $memberSAM
            $CSVLine | Add-Member -NotePropertyName "UserUPN" -NotePropertyValue $memberUPN
        }
        $CSVTable += $CSVLine
        Clear-Variable $CSVLine
    }
$CSVTable | Export-Csv -NoTypeInformation .\ADGroupMembers.csv