$DC = $env:LOGONSERVER -replace ‘\\’,""

repadmin /syncall $DC /APed

$script =
{
    & "C:\Program Files\Microsoft Azure AD Sync\Bin\DirectorySyncClientCmd.exe" delta
}

Invoke-Command -ComputerName BOSCORPAADC -ScriptBlock $script