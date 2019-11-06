$newArray = @(1,2,3,4,5,6,7,8,9,10)
$x = 9
do {"$x`t$($newArray[$x])";
$x--}
while ($x -ge 0) 