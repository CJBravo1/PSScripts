[array]$computers = Get-Content C:\Temp\Computers.txt

foreach($computer in $computers)
{
    try
    {
         $exists = Get-ADComputer -Identity $computer -ErrorAction SilentlyContinue
    }
    catch
    {
        Write-Host $Computer " does not exist"
    }
    
    if($null -ne $exists)
    {
        Set-ADComputer -Identity $computer -Enabled $false
        Get-ADComputer -Identity $computer | Format-List Name, Enabled
    }
    
    Clear-Variable exists
}