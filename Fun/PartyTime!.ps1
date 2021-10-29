#AUTHOR: CHRIS JORENBY
$x = 0
Write-Host "What Time is it?"
Start-Sleep 5
while ($x -eq 0)
	{
	$random = new-object random
	$color = [System.ConsoleColor]$random.next(1,16)
	Write-Host "Its Party Time!" -ForegroundColor $color 
	start-sleep .5
	}
