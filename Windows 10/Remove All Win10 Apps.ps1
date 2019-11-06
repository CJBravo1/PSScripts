Get-AppxPackage | select Name
Switch ($ans = Read-Host -Prompt "Do you want to remove these Apps?")
    {
    Yes
        {
        Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue -Confirm:$false
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