#Email Info
$smtpServer="smtprelay.verisae.int"
$expireindays = 6
$from = "Company Administrator <cjorenby@verisae.com>"
#$logFile = "C:\Temp\log.csv


#Get ADUsers
#$Userlist = Get-ADUser -Properties * -Filter * -SearchBase "OU=People,DC=verisae,DC=int" | where {$_.Enabled -eq $TRUE}
#$Userlist = Get-ADUser -Identity cjorenby -Properties *
$Userlist =  @("cjorenby","cdwyer","panderson","agunness")
$VerisaeALL = "verisaeall@verisae.com"

Foreach ($user in $Userlist)
	{
	$user = Get-ADUser -Identity $user -Properties *
	$Name = $user.Name
	$emailaddress = $user.EmailAddress
	$passwordLastSet = $user.PasswordLastSet
	
	
	
	
	
	#E-mail Message
	$subject = "$name, Your Password Will Expire!!!"
	
  	$body ="
    Dear $name,
    <p> This is an important message <br>
    Please reply to this message to confirm that you received it<br>
    <p>Thanks, <br> 
    </P>"
	
	
	
	$Name
	$emailaddress
	$passwordLastSet
	$subject
	
	#Send Email
	#Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -priority High
	}
	
	
	