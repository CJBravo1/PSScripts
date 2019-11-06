Do
{
$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$adminUN = ([ADSI]$sidbind).mail.tostring()
$error.clear()
$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

If ($error.count -gt 0) { 
Clear-Host
$failed = Read-Host "Login Failed! Retry? [y/n]"
	if ($failed  -eq 'n'){exit}
}
} While ($error.count -gt 0)
Import-PSSession $Session 

$dateEnd = Read-Host "End date of search mm/dd/yyyy (Leave blank for today)"
If ($dateEnd -eq ''){
$dateEnd = get-date 
}

$daysBack = Read-Host "Number of date to search back from end date mm/dd/yyyy(Leave blank for 7 days)"
If ($daysBack -lt 1){
$daysBack = $dateEnd.AddDays(-7)
}

$dateStart = $dateEnd.AddDays(-$daysBack)

Write-Host "Search from $dateStart to $dateEnd"
$recipient = Read-Host "Recipient email address (leave blannk to search by sender only)"
$sender = Read-Host "Sender email address (leave blannk to search by recipeint only)"

$dateShort = Get-Date -UFormat "%Y%m%d%H%S"

If ($recipient -eq ''){
Get-MessageTrace -SenderAddress $sender -StartDate $dateStart -EndDate $dateEnd | Select-Object Received, SenderAddress, RecipientAddress, Subject, Status, ToIP, FromIP, Size, MessageID, MessageTraceID | Export-Csv ".\$sender-$dateShort.csv" -Append 
Exit
}

If ($sender -eq ''){
Get-MessageTrace -RecipientAddress $recipient -StartDate $dateStart -EndDate $dateEnd | Select-Object Received, SenderAddress, RecipientAddress, Subject, Status, ToIP, FromIP, Size, MessageID, MessageTraceID | Export-Csv ".\$recipient-$dateShort.csv" -Append 
Exit
}

Get-MessageTrace -RecipientAddress $recipient -SenderAddress $sender -StartDate $dateStart -EndDate $dateEnd | Select-Object Received, SenderAddress, RecipientAddress, Subject, Status, ToIP, FromIP, Size, MessageID, MessageTraceID | Export-Csv ".\$sender-$recipient-$dateShort.csv" -Append 