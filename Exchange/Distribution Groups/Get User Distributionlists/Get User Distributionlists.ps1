#Get Login Credentials
$UserCredential = Get-Credential -Message "Enter your Office 365 Credentials"

#Make new session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

#Connect to PsSession
Import-PSSession $Session -WarningAction SilentlyContinue

Write-Host "Enter Reference EMail Address" -ForegroundColor Yellow
$InputMail = Read-Host

$refMail = Get-Mailbox -Identity $InputMail
$refDN = $refMail.Distinguishedname
$refDist = Get-DistributionGroup -ResultSize Unlimited -Filter $("Members -like '$refDN'")
if ($refDist -eq $null)
        {
        Write-Host "Either the Mailbox Does not exist, or this mailbox does not have any Distribution list subscriptions" -ForegroundColor Yellow -BackgroundColor Red
        }
else
        {
        $refDist
        $refDist | Export-Csv -NoTypeInformation .\"$inputMail "Distrolists.csv
        }