
#$ErrorActionPreference = "Ignore"

#Get Credentials
$MGMTMAccount = Get-Credential -Credential mgmt\m0155443
#$TLRMAccount = Get-Credential -Credential tlr\m0155443
$DebugPreference = "Continue"


#Get Hostlist 
$Hostlist = Get-Content 'c:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Hibernation\Hibernation hostlist.txt'
#echo $Hostlist

#MGMT Domain
ForEach ( $ObjHostlist in $Hostlist ){
	New-PSDrive -Name Z -PSProvider FileSystem -Root \\$ObjHostlist\c$ -Credential $MGMTMAccount -ErrorAction Ignore | Select-Object Length, FullName
	#if (!$?) {Write-Host "Cannot connect to $ObjHostlist." -ForegroundColor Yellow}
	
	#TLR Domain
	#if ( $ObjHostlist -contains '*tlr.thomson.com"') 
	#	{New-PSDrive -Name Z -PSProvider FileSystem -Root \\$ObjHostlist\c$ -Credential $TLRMAccount -ErrorAction Ignore}
Write-Debug -Message "Cannot connect to $ObjHostlist"
	
	#TLRG.com Domain
	#if ($ObjHostlist -contains '*tlrg.com')
	#{New-PSDrive -Name Z -PSProvider FileSystem -Root \\$ObjHostlist\c$ -Credential $TLRMAccount -ErrorAction Ignore}
	
	
	
	Get-ChildItem z: -Force | Where-Object {$_.Name -eq 'hiberfil.sys'} -ErrorAction Ignore | Export-CSV -Path c:\Users\U0155443\Desktop\hiberfil.csv -Append
	#if (!$?) {Write-Host " Try Changing your password" -ForegroundColor Yellow}
Write-Debug -Message "Cannot connect to $ObjHostlist"
	
	Remove-PSDrive Z | Export-Csv -Path c:\Users\U0155443\Desktop\hiberfil.csv -Append -ErrorAction Ignore
	#if (!$?) {Write-Host "Unable to Remove Z Drive does not exist" -ForegroundColor Yellow}
Write-Debug -Message "Cannot connect to $ObjHostlist"

 }
