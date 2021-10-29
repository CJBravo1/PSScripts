#Gather User Photos
$userphotos = ls *.jpg

#Start Foreach Loop
foreach ($photo in $userphotos){

#Rename each name as the proper Email Address
$mailbox = $photo.Name -replace ".jpg","@domain.org"

#Get the mailbox with the new name
#Show mailbox in progress
$mailbox = Get-Mailbox $mailbox -ErrorVariable NoMailbox -ErrorAction SilentlyContinue
if ($mailbox -eq $null) 
{
Write-Host $($photo.Name -replace ".jpg","") mailbox could not be found -ForegroundColor Yellow -BackgroundColor Red
}
else 
{
Write-Host $mailbox.samaccountname -ForegroundColor Cyan
}

#Set the photo for the end user
Set-UserPhoto -Identity $mailbox.SamAccountName -PictureData ([System.IO.File]::ReadAllBytes($photo)) -Confirm:$false -ErrorAction SilentlyContinue
}
