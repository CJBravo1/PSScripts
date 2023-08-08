write-host "##################################################
#              !Remove Windows Apps!             #
##################################################" -ForegroundColor Green 

$AppList = @("Microsoft.3DBuilder";"Microsoft.WindowsAlarms";"Microsoft.WindowsCalculator";"microsoft.windowscommunicationsapps";"Microsoft.WindowsCamera";"Microsoft.MicrosoftOfficeHub";"Microsoft.SkypeApp";"Microsoft.Getstarted";"Microsoft.ZuneMusic";"Microsoft.WindowsMaps";"Microsoft.MicrosoftSolitaireCollection";"Microsoft.BingFinance";"Microsoft.ZuneVideo";"Microsoft.BingNews";"
Microsoft.Office.OneNote";"Microsoft.People";"Microsoft.WindowsPhone;Microsoft.Windows.Photos";"Microsoft.WindowsStore";"Microsoft.BingSports";"Microsoft.BingWeather";"Microsoft.XboxApp")

#Write-Host "Are you sure you want to remove all Pre-Installed Windows Apps?"

foreach ($appName in $AppList) 
		{
		$app = Get-AppxPackage $appName
		Write-Host $app.Name -ForegroundColor Green
		}
		Switch ($ans = Read-Host -Prompt "Do you want to remove these Apps?") 
			{
			Yes
				{
				$app = $null
				foreach ($app in $AppList)
					{
					#(Get-AppxPackage $app) | Remove-AppxPackage -Whatif
					Write-Host $app " DELETED!" -ForegroundColor Yellow -BackgroundColor Red
					}
				}
			
			No
				{
				Write-Host "Script Canceled" -ForegroundColor Red
				}
			
			else
				{
				Write-Host "Script Canceled" -ForegroundColor Red
				}
			}
		