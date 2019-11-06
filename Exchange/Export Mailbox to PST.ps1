$IE=new-object -com internetexplorer.application
$IE.navigate2("https://protection.office.com/")
$IE.visible=$true
Clear-Host
Read-Host "Opening O365 Security & Compliance in IE. Please Log in there and then press any key to continue..."
Do
{
$error.clear()
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
If ($error.count -gt 0) { 
Clear-Host
$failed = Read-Host "Login Failed! Retry? [y/n]"
	if ($failed  -eq 'n'){exit}
}
} While ($error.count -gt 0)


Import-PSSession $Session
Clear-Host
$username = Read-Host "Enter Email to backup"


New-ComplianceSearch -Name $username"-Export" -ExchangeLocation $username -AllowNotFoundExchangeLocationsEnabled $true
Start-ComplianceSearch -Identity $username"-Export"

Do
{
$error.clear()
"Waiting on O365..."
Start-Sleep 5
New-ComplianceSearchAction -SearchName $username"-Export" -export -WhatIf
Clear-Host
} While ($error.count -gt 0)
New-ComplianceSearchAction -SearchName $username"-Export" -export


$IE.navigate2("https://protection.office.com/#/contentsearch")
$IE.visible=$true
Remove-PSSession $Session