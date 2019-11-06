
#Computer account password change information http://support.microsoft.com/?id=154501
#http://blogs.technet.com/b/askds/archive/2009/02/15/test2.aspx
#http://blogs.technet.com/b/heyscriptingguy/archive/2008/11/19/how-can-i-find-old-computer-accounts.aspx

#Windows 2000 and newer is 30 days
#$hostedDC = <your domain controller here>




#Oldest date a computer could have changed its password and still be considered valid
$PhoneHomedeadline = Get-Date "1/1/2013"

#If this is set to true a DNS lookup and ping will be performed on a workstations not in target forest
$IPCheck = $true



Import-Module activedirectory
$Ping = New-Object system.net.networkinformation.ping
$date = Get-Date -format M.d.yyyy
$a = Get-Date
$time = $a.ToShortTimeString()
$time = $time.replace(":","-")
$MigratedComputerObject = 0 
$MigrationCandiate = 0
$totalcomputeraccounts = 0

#Output file path
$workstationStatsRollup = "C:\Users\administrator.EAD\Documents\Chris - " + $date + " " + $time + ".csv"
		
$maxOldLogonDays = 30

	$count = 0
	#http://technet.microsoft.com/en-us/library/ff730967.aspx
	$objsearcher = new-object System.DirectoryServices.DirectorySearcher
	#$objSearcher.Filter = (“(objectCategory=computer)”)
	$objSearcher.Filter = "(&(objectcategory=computer)(|(operatingSystem=Windows 7*)(operatingSystem=Windows XP*)(operatingSystem=*Windows 2000 Professional*)(operatingSystem=*NT 4.0 workstation*)(operatingSystem=*Vista*)))"
	#$objSearcher.SearchRoot = $objDomain
	$objSearcher.PageSize = 1000
	$objSearcher.SearchScope = "Subtree"
	$colProplist = "name","operatingsystem","lastlogontimestamp","distinguishedName","whencreated","DNSHostname"
	foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}
	$objSearcher.FindAll() |

	#This fails out of the loop of there is corrupt record when running in powergui
	#Get-ADComputer -Filter { (operatingsystem -like "*Windows 2000 Professional*") -or (operatingsystem -like "*NT 4.0 workstation*") -or (operatingsystem -like "Windows 7*") -or (operatingsystem -like	"Windows XP Professional") -or (operatingsystem -like "*Vista*")} -Server $sourceforestDC -Credential $CurrentCredentials -Properties operatingsystem,lastlogontimestamp,created |
	
	Foreach-Object `
		{
			$obj = New-Object PSObject
			Write-Host "Processing computer " $_.Properties.Item("distinguishedName")
			$hostedcomputername = [string]$_.Properties.Item("name")
			$obj | Add-Member NoteProperty 'Workstation Name' ($hostedcomputername)
			$sourceforestworkstationDN = [string]$_.Properties.Item("distinguishedName")
			$sourceforestworkstationFQDN = [string]$_.Properties.Item("dnshostname")
			
			if ($sourceforestworkstationFQDN -eq "")
				{
				Write-Host "WorkstationFQDNotFound"
				$sourceforestworkstationFQDN = "WorkstationFQDNotFound"
				}
				
			$obj | Add-Member NoteProperty 'Workstation DN' ($sourceforestworkstationDN)
			$obj | Add-Member NoteProperty 'OS Name' ([string]$_.Properties.Item("operatingsystem"))
			$obj | Add-Member NoteProperty 'Computer Account create date' ([string]$_.Properties.Item("whencreated"))
			
			#if it was created less than a day ago report it
			$whenCreateddate = get-date ([string]$_.Properties.Item("whencreated"))
			
		
			$rawLogon = ""
			$rawLogon = $_.Properties.Item("lastlogontimestamp")
			$convertedLogOn = [datetime]::FromFileTime([int64]::Parse($rawLogon))
			$obj | Add-Member NoteProperty 'Workstation lastlogontimestamp' ($convertedLogOn)


			
							if($IPCheck -eq $true)
								{
									#DNS Check
									$dnsaddress = ""
									$dnsaddress = [system.net.dns]::GetHostAddresses($sourceforestworkstationFQDN)
									if ($dnsaddress -eq "")
									  {
									    $DNSresolved = $False
										Write-Host "Can't resolve " $sourceforestworkstationFQDN " to an IP address"
										$obj | Add-Member NoteProperty 'DNS IP Address' ("Not Found")
										$obj | Add-Member NoteProperty 'Multiple DNS Records returned' ("No")
										$obj | Add-Member NoteProperty 'Responded to ping' ("No")
										$obj | Add-Member NoteProperty 'File copy error result' ("")
										$obj | Add-Member NoteProperty 'File copy successful' ("No")
										$obj | Add-Member NoteProperty 'Name returned from IP Address' ("")
									  }
									else
									  {
									  	$DNSresolved = $True
										Write-Host $sourceforestworkstationFQDN " resolved to "  $dnsaddress
											if ($dnsaddress.count -gt 1)
												{
												Write-Host "Multiple IP address were returned from the Query"
												$obj | Add-Member NoteProperty 'Multiple DNS Records returned' ("Yes")
												foreach($IP in $dnsaddress)
													{
													if ($IP.AddressFamily -like "InterNetwork")
														{
														$ipaddresses = $IP.ToString() + ";"
														$obj | Add-Member NoteProperty 'DNS IP Address' ($ipaddresses)
														$finalIP = $IP.ToString()														
														}
														else
														{
														Write-Host "Ignoring IPV6 addresses"
														}			
													
													}						
												
												}
												else
												{
												$obj | Add-Member NoteProperty 'Multiple DNS Records returned' ("No")
												$finalIP = $dnsaddress
												$obj | Add-Member NoteProperty 'DNS IP Address' ($finalIP)
												}
										  }
									
									
									#Ping Test
									 if($DNSresolved -eq $true)
									 	{
										 if($finalIP -ne "")
										 	{
											 $connection = $Ping.send($finalIP)
												  if ($connection.Status -eq "Success")
									  				{				
													Write-Host "Pinged " $finalIP -BackgroundColor Green -ForegroundColor White
													$obj | Add-Member NoteProperty 'Responded to ping' ("Yes")
													#File copy test
													$filecopypath = "\\" + $sourceforestworkstationFQDN + "\admin$\debug\selfservepreflight.txt"
													Write-Host "Begin file copy test to " $filecopypath -BackgroundColor blue -ForegroundColor White
													$filecopydate = get-date
													
													
#													Try/catch statements can only catch terminating errors (these usually indicate a severe error). 
#													PowerShell also has the concept of non-terminating errors. 
#													The file-in-use error you see is a non-terminating error. 
#													This is good from the perspective that if you were moving thousands of files 
#													and one had its target in use, the command doesn't crap out it keeps going. 
#													You have two choices here. You can ignore these errors by setting the ErrorAction parameter to SilentlyContinue (value of 0) e.g.:

													try
														{
														New-Item $filecopypath -type file -force -value ("Self_serve_preflight " + $filecopydate) -ErrorAction Stop
														#$obj | Add-Member NoteProperty 'File copy error result' ("")
														}
														catch  														
														{
														#$_.GetType().FullName
														Write-Error $_.Exception.Message
														$obj | Add-Member NoteProperty 'File copy error result' ($_.Exception.Message)
														$obj | Add-Member NoteProperty 'File copy successful' ("No")
														}
														
														
													$filetest = Test-Path $filecopypath
														if($filetest -eq -$true)
															{
															$obj | Add-Member NoteProperty 'File copy successful' ("Yes")
															Write-Host "File copy test sucessful to "  $filecopypath -BackgroundColor Green -ForegroundColor White
															$obj | Add-Member NoteProperty 'File copy error result' ("")
															}
															else
															{
															#$obj | Add-Member NoteProperty 'File copy successful' ("No")
															}
													
													$ipobjectinfo = ""
													$ipobjectinfo = get-wmiobject  Win32_ComputerSystem -computername $finalIP
													$obj | Add-Member NoteProperty 'Name returned from IP Address' ($ipobjectinfo.Name)
													$ipobjectinfo = ""
													}
													else
													{
													write-host $sourceforestworkstationFQDN " did not respond to ping" -ForegroundColor Red -BackgroundColor Yellow
													$obj | Add-Member NoteProperty 'Responded to ping' ("No")
													$obj | Add-Member NoteProperty 'File copy successful' ("No")
													$obj | Add-Member NoteProperty 'File copy error result' ("")
													$obj | Add-Member NoteProperty 'Name returned from IP Address' ("")
													}
											}
										}

								}
								else
								{
								$obj | Add-Member NoteProperty 'DNS IP Address' ("")
								$obj | Add-Member NoteProperty 'Multiple DNS Records returned' ("")
								$obj | Add-Member NoteProperty 'Responded to ping' ("")
								}

		
			$Hostedcomputer = ""
			$dnsaddress = ""
			$finalIP = ""
			$Results += @($obj)	
			$count ++
			$totalcomputeraccounts ++
			Write-Host "Processed " $count
		}


#Write results to a CSV
$results | Export-CSV $logfilename  -NoTypeInformation

Write-Host "Processed " $totalcomputeraccounts
Write-Host "Script Complete"