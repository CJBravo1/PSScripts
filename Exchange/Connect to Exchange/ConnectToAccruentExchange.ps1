#Change Window Title
$host.ui.RawUI.WindowTitle = "Accruent Exchange"

$host.ui.RawUI.WindowTitle = "Accruent Exchange EXS41.accruent.com"
$ExchangeSession = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri http://exs41.accruent.com/powershell
Import-PSSession $ExchangeSession -WarningAction SilentlyContinue | out-null

Write-Host "Connected to EXS41.accruent.com" -ForegroundColor Cyan
Write-Host "Have a lot of fun..." -ForegroundColor Green