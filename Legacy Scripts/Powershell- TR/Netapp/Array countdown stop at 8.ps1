$newArray = @(1,2,3,4,5,6,7,8,9,10)
for ($x = 0; $x -le 9;$x++ )
{ if ($x -eq 1) {continue}
elseif ($x -eq 4) {continue} 
Write-Output "$($newArray[$x])"} 
