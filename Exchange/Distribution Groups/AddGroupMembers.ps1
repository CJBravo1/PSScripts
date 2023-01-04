ls | ForEach-Object {
 $Group = Import-Csv $_.FullName
 $GroupName = $_
 $GroupName = $GroupName -replace ".csv",""
 write-host $GroupName -ForegroundColor cyan
 foreach ($member in $Group) {
 Write-Host $member.Identity -ForegroundColor Green
 Add-DistributionGroupMember -Identity $GroupName -Member $member.Identity}
}