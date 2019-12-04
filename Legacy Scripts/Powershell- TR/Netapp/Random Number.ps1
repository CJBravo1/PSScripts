$randomNum = Get-Random -Minimum 1 -Maximum 20
if ($randomNum -gt 10)
    {write-host "Winner!" -ForegroundColor Cyan}
else
    {write-host "Fail!" -ForegroundColor Red}
write-host "The Number was" $randomNum -ForegroundColor Yellow