
Clear-Host
Write-Host --------------------------------------------------------------------
Write-Host 'THIS TOOL IS USED TO ADD A USER TO THE LOCAL ADMINS GROUP'
Write-Host --------------------------------------------------------------------
Write-Host 'The list of hosts need to be in "C:\temp\serverlist.txt"'
Write-Host 'Output will be logged to "c:\temp\USERoutput.txt"'
Write-Host 'Provide Credentials for Remote Hosts'

$Cred = Get-Credential
$Servers = Get-content C:\temp\serverlist.txt

if (Test-Path 'c:\temp\USERoutput.txt') {
      Remove-Item 'c:\temp\USERoutput.txt' -Force
}

$myArray = @()
$Servers | foreach {

Write-Host $_ -ForegroundColor Green

$remotecommand = Invoke-Command -Computername $_ -Cred $Cred -ScriptBlock {
      Write-Output "===================="
      Get-Content env:computername
      Write-Output "===================="
    $Group = [ADSI]("WinNT://localhost/Administrators,Group")
    $Group.add("WinNT://TLR/REST-PTS-NTLTECHADMIN-ServerAdmins,user")
      #$Group.remove("WinNT://MGMTSEC/REST-LEGAL-LITHOST-ServerAdmins,user")
      NET LOCALGROUP "Administrators"     
}

$remotecommand

foreach ($output in $remotecommand) {
            $myArray += @($output)
      }

}

$myArray | Out-File -FilePath c:\temp\USERoutput.txt -Append

Invoke-Item c:\temp\USERoutput.txt

