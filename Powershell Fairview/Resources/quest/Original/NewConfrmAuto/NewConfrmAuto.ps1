ADD-PSSNAPIN QUEST.ACTIVEROLES.ADMANAGEMENT
ADD-PSSNAPIN MICROSOFT.EXCHANGE.MANAGEMENT.POWERSHELL.ADMIN

Import-CSV c:\scripts\quest.csv | ForEach{
New-QADUser -DISPLAYNAME $_.DISPLAY -Name $_.DISPLAY -ParentContainer Fairview.org/Exchange/Resources -USERPRINCIPALNAME $_.UPN -SamAccountName $_.Sam -LastName $_.display -UserPassword $_.password}

Start-Sleep -Seconds 20


Import-CSV c:\scripts\quest.csv | ForEach{
enable-mailbox -Identity $_.display -Database $_.DB}

Start-Sleep -Seconds 20

import-csv "c:\scripts\quest.csv" | foreach{
set-mailbox -identity $_.DISPLAY -TYPE Room}

import-csv "c:\scripts\quest.csv" | foreach{
Set-MailboxCalendarSettings -Identity $_.display -AutomateProcessing:AutoAccept -AllBookInPolicy:$True -AllRequestOutOfPolicy:$False -AllRequestInPolicy:$False -AllowConflicts:$False -BookingWindowInDays:730  -ConflictPercentageAllowed:5 -MaximumConflictInstances:25 -DeleteSubject:$False -AddAdditionalResponse:$True -AdditionalResponse:"Please contact the owner of the room to report any problems.”}