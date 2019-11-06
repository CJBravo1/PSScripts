Do
{

$windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$sidbind = "LDAP://<SID=" + $windowsIdentity.user.Value.ToString() + '>'
$adminUN = ([ADSI]$sidbind).mail.tostring()
	Clear-Host
	Write-Host "Enter your credentials in the popup."
$error.clear()
$UserCredential = Get-Credential -UserName $adminUN -Message "Enter your password"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/?proxymethod=rps -Credential $UserCredential -Authentication Basic -AllowRedirection

If ($error.count -gt 0) { 
Clear-Host
$failed = Read-Host "Login Failed! Retry? [y/n]"
	if ($failed  -eq 'n'){exit}
}
} While ($error.count -gt 0)
Import-PSSession $Session

function Get-Image
{
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
		[Alias('FullName')]
		[string]$file)
	
	process
	{
		$realItem = Get-Item $file -ErrorAction SilentlyContinue
		if (-not $realItem) { return }
		$image = New-Object -ComObject Wia.ImageFile
		try
		{
			$image.LoadFile($realItem.FullName)
			$image |
			Add-Member NoteProperty FullName $realItem.FullName -PassThru |
			Add-Member ScriptMethod Resize {
				param ($width,
					$height,
					[switch]$DoNotPreserveAspectRatio)
				$image = New-Object -ComObject Wia.ImageFile
				$image.LoadFile($this.FullName)
				$filter = Add-ScaleFilter @psBoundParameters -passThru -image $image
				$image = $image | Set-ImageFilter -filter $filter -passThru
				Remove-Item $this.Fullname
				$image.SaveFile($this.FullName)
			} -PassThru |
			Add-Member ScriptMethod Crop {
				param ([Double]$left,
					[Double]$top,
					[Double]$right,
					[Double]$bottom)
				$image = New-Object -ComObject Wia.ImageFile
				$image.LoadFile($this.FullName)
				$filter = Add-CropFilter @psBoundParameters -passThru -image $image
				$image = $image | Set-ImageFilter -filter $filter -passThru
				Remove-Item $this.Fullname
				$image.SaveFile($this.FullName)
			} -PassThru |
			Add-Member ScriptMethod FlipVertical {
				$image = New-Object -ComObject Wia.ImageFile
				$image.LoadFile($this.FullName)
				$filter = Add-RotateFlipFilter -flipVertical -passThru
				$image = $image | Set-ImageFilter -filter $filter -passThru
				Remove-Item $this.Fullname
				$image.SaveFile($this.FullName)
			} -PassThru |
			Add-Member ScriptMethod FlipHorizontal {
				$image = New-Object -ComObject Wia.ImageFile
				$image.LoadFile($this.FullName)
				$filter = Add-RotateFlipFilter -flipHorizontal -passThru
				$image = $image | Set-ImageFilter -filter $filter -passThru
				Remove-Item $this.Fullname
				$image.SaveFile($this.FullName)
			} -PassThru |
			Add-Member ScriptMethod RotateClockwise {
				$image = New-Object -ComObject Wia.ImageFile
				$image.LoadFile($this.FullName)
				$filter = Add-RotateFlipFilter -angle 90 -passThru
				$image = $image | Set-ImageFilter -filter $filter -passThru
				Remove-Item $this.Fullname
				$image.SaveFile($this.FullName)
			} -PassThru |
			Add-Member ScriptMethod RotateCounterClockwise {
				$image = New-Object -ComObject Wia.ImageFile
				$image.LoadFile($this.FullName)
				$filter = Add-RotateFlipFilter -angle 270 -passThru
				$image = $image | Set-ImageFilter -filter $filter -passThru
				Remove-Item $this.Fullname
				$image.SaveFile($this.FullName)
			} -PassThru
			
		}
		catch
		{
			Write-Verbose $_
		}
	}
}

function Add-CropFilter
{
	param (
		[Parameter(ValueFromPipeline = $true)]
		[__ComObject]$filter,
		[__ComObject]$image,
		[Double]$left,
		[Double]$top,
		[Double]$right,
		[Double]$bottom,
		[switch]$passThru
	)
	
	process
	{
		if (-not $filter)
		{
			$filter = New-Object -ComObject Wia.ImageProcess
		}
		$index = $filter.Filters.Count + 1
		if (-not $filter.Apply) { return }
		$crop = $filter.FilterInfos.Item("Crop").FilterId
		$isPercent = $true
		if ($left -gt 1) { $isPercent = $false }
		if ($top -gt 1) { $isPercent = $false }
		if ($right -gt 1) { $isPercent = $false }
		if ($bottom -gt 1) { $isPercent = $false }
		$filter.Filters.Add($crop)
		if ($isPercent -and $image)
		{
			$filter.Filters.Item($index).Properties.Item("Left") = $image.Width * $left
			$filter.Filters.Item($index).Properties.Item("Top") = $image.Height * $top
			$filter.Filters.Item($index).Properties.Item("Right") = $image.Width * $right
			$filter.Filters.Item($index).Properties.Item("Bottom") = $image.Height * $bottom
		}
		else
		{
			$filter.Filters.Item($index).Properties.Item("Left") = $left
			$filter.Filters.Item($index).Properties.Item("Top") = $top
			$filter.Filters.Item($index).Properties.Item("Right") = $right
			$filter.Filters.Item($index).Properties.Item("Bottom") = $bottom
		}
		if ($passthru) { return $filter }
	}
}

Function Get-FileName($initialDirectory)
{
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = "JPG (*.jpg)| *.jpg"
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
}

function Set-ImageFilter
{
	param (
		[Parameter(ValueFromPipeline = $true)]
		$image,
		[__ComObject[]]$filter,
		[switch]$passThru
	)
	
	process
	{
		if (-not $image.LoadFile) { return }
		$i = $image
		foreach ($f in $filter)
		{
			$i = $f.Apply($i.PSObject.BaseObject)
		}
		if ($passThru)
		{
			$i
		}
	}
}
function Add-ScaleFilter
{
	param (
		[Parameter(ValueFromPipeline = $true)]
		[__ComObject]$filter,
		[__ComObject]$image,
		[Double]$width,
		[Double]$height,
		[switch]$DoNotPreserveAspectRatio,
		[switch]$passThru
	)
	
	process
	{
		if (-not $filter)
		{
			$filter = New-Object -ComObject Wia.ImageProcess
		}
		$index = $filter.Filters.Count + 1
		if (-not $filter.Apply) { return }
		$scale = $filter.FilterInfos.Item("Scale").FilterId
		$isPercent = $true
		if ($width -gt 1) { $isPercent = $false }
		if ($height -gt 1) { $isPercent = $false }
		$filter.Filters.Add($scale)
		$filter.Filters.Item($index).Properties.Item("PreserveAspectRatio") = "$(-not $DoNotPreserveAspectRatio)"
		if ($isPercent -and $image)
		{
			$filter.Filters.Item($index).Properties.Item("MaximumWidth") = $image.Width * $width
			$filter.Filters.Item($index).Properties.Item("MaximumHeight") = $image.Height * $height
		}
		else
		{
			$filter.Filters.Item($index).Properties.Item("MaximumWidth") = $width
			$filter.Filters.Item($index).Properties.Item("MaximumHeight") = $height
		}
		if ($passthru) { return $filter }
	}
}


Do
{
	Clear-Host
	$userEmail = Read-Host "What is the email of the account you want to set the picture for?"
	Clear-Host
	Write-Host "Now select the picture"
	
	$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
	
	$inputfile = Get-FileName $executingScriptDirectory
	$image = New-Object -ComObject Wia.ImageFile
	$image = Get-Image $inputfile
	Clear-Host
	Write-Host "Cropping and resizing image..."
	$width = $image.Width
	$height = $image.Height
	if ($width -gt $height)
	{
		$subtract = $width -= $height
		$divide = $subtract /= 2
		$image = $image | Set-ImageFilter -filter (Add-CropFilter -image $image -left $divide -right $divide -passThru) -passThru
		$image = $image | Set-ImageFilter -filter (Add-ScaleFilter -Width 648 -Height 648 -passThru) -passThru
	}
	elseif ($height -gt $width)
	{
		$subtract = $height -= $width
		$divide = $subtract /= 2
		$image = $image | Set-ImageFilter -filter (Add-CropFilter -image $image -top $divide -bottom $divide -passThru) -passThru
		$image = $image | Set-ImageFilter -filter (Add-ScaleFilter -Width 648 -Height 648 -passThru) -passThru
	}
	Clear-Host
	Write-Host "Saving cropped image..."
		$save = ("$executingScriptDirectory\temp.jpg")
	if (Test-Path $save) { Remove-Item -Path $save -force }
	$image.SaveFile("$save")
	Clear-Host
	Write-Host "Uploading to office 365..."
	Set-UserPhoto $userEmail -PictureData ([System.IO.File]::ReadAllBytes("$save")) -Confirm:$false
	Remove-Item -Path $save -force
	Clear-Host
	Write-Host "Scaling image to 96 x 96 pixels for ADUC..."
	$image = $image | Set-ImageFilter -filter (Add-ScaleFilter -Width 96 -Height 96 -passThru) -passThru
	$image.SaveFile("$save")
	Clear-Host
	Write-Host "Applying to ADUC property..."
	Import-RecipientDataProperty -Identity $userEmail -Picture -FileData ([Byte[]]$(Get-Content -Path "$save" -Encoding Byte -ReadCount 0))
	Remove-Item -Path $save -force
	
	$repeat = Read-Host "Do you need to change another image? [y/n]"
}
While ($repeat -ne "n")
{ $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") }