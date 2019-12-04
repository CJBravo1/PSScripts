if (Test-Path 'c:\temp\output.txt') {
      Remove-Item 'c:\temp\output.txt' -Force
}

$chassis=get-content 'C:\Users\U0155443\SkyDrive\Documents\Windows\Powershell\Ping_Hostlist.txt'
$chassis | foreach {

      If (Test-Connection $_ -Count 1 -Quiet) {
        write-host $_ "online"
        nslookup $_
        }
      Else {
        write-host $_ "offline"
        "$_ offline" | Out-File -FilePath c:\temp\output.txt -Append
        nslookup $_
        }  
}

Invoke-Item c:\temp\output.txt
