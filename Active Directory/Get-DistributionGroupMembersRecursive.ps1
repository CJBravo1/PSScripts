# Written by Regan Vecera
# 5.23.2018
# Intended to get group membership of nested groups

$groupname = "All at Accruent"
$saveto = ".\$groupname.csv"
Do
{
	$error.clear()
	$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
	$adminUN = ([ADSI]$sidbind).mail.tostring()
	$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

	If ($error.count -gt 0) { 
	#Clear-Host
	$failed = Read-Host "Login Failed! Retry? [y/n]"
		if ($failed  -eq 'n'){exit}
	}
} While ($error.count -gt 0)

# Connect to Exchange Online
Write-Host "Importing Powershell Sessions" -ForegroundColor Green
Import-PSSession $Session -AllowClobber


Function get_member_recurse ($mailbox){
	Get-DistributionGroupMember $mailbox | foreach {
	if($_.RecipientType -eq "UserMailbox") 
	{
		$list += [string]($_.PrimarySMTPAddress) + ","
	} 
	else {
		get_member_recurse($_.Name)
	}
	}
	return $list
}


Function hash2obj($data) {
    $stuff = @();
    
    foreach($row in $data) {
        $obj = new-object PSObject
		$name = Get-ADUser -Filter {UserPrincipalName -eq $row} | Select DisplayName
        $obj | add-member -membertype NoteProperty -name "Email" -value $row
		
        $stuff += $obj
    }
    
    return $stuff;
}

[string]$members = get_member_recurse($groupname)

#$members is just a blob of email addresses, so split it to form an array
$array = $members.split(",")
$array = $array | Select -unique

#Arrays cannot be exported to CSV, so we need to convert to a hashtable first
$object = hash2obj($array)
$object | Export-Csv -Path $saveto -NoTypeInformation

Exit-PSSession
