ADD-PSSNAPIN QUEST.ACTIVEROLES.ADMANAGEMENT
ADD-PSSNAPIN MICROSOFT.EXCHANGE.MANAGEMENT.POWERSHELL.ADMIN

Import-CSV c:\scripts\quest.csv | ForEach{
New-QADUser -DISPLAYNAME $_.DISPLAY -Name $_.DISPLAY -ParentContainer Fairview.org/Exchange/Resources -USERPRINCIPALNAME $_.UPN -SamAccountName $_.Sam -LastName $_.display -UserPassword $_.password}

Start-Sleep -Seconds 20


Import-CSV c:\scripts\quest.csv | ForEach{
enable-mailbox -Identity $_.display -Database $_.DB}