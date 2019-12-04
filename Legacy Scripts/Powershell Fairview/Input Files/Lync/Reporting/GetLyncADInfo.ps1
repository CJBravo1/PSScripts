
 $ErrorActionPreference = 'SilentlyContinue'
 Import-Module ActiveDirectory
 $Output = @()

 Foreach ($LyncUser in Get-CSUser -ResultSize Unlimited)
 {
 $ADUser = Get-ADUser -Identity $LyncUser.SAMAccountName -Properties Department, Title
 $Output += New-Object PSObject -Property @{DisplayName=$LyncUser.DisplayName; Department=$ADUser.Department; Title=$ADUser.Title; SAMAccountName=$ADUser.sAMAccountName; SIPAddress=$LyncUser.SIPAddress; EVEnabled=$LyncUser.EnterpriseVoiceEnabled}
 }

 $Output | Export-CSV -Path C:\export\LyncADInfo.csv
 $Output | FT DisplayName, Title, Department, SAMAccountName, SIPAddress, EVEnabled