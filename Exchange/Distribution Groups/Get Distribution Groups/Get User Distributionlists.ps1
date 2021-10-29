#Make new session
$Session = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"}

if ($null -eq $session)
{
    Write-Host "No Exchange Session Established..." -foregroundcolor Red
}

Write-Host "Enter Reference EMail Address" -ForegroundColor Yellow
$InputMail = Read-Host

$refMail = Get-Mailbox -Identity $InputMail
$refDN = $refMail.Distinguishedname
$refDist = Get-DistributionGroup -ResultSize Unlimited -Filter $("Members -like '$refDN'")
if ($null -eq $refDist)
        {
        Write-Host "Either the Mailbox Does not exist, or this mailbox does not have any Distribution list subscriptions" -ForegroundColor Yellow -BackgroundColor Red
        }
else
        {
        $refDist
        $refDist | Export-Csv -NoTypeInformation .\"$inputMail "Distrolists.csv
        }