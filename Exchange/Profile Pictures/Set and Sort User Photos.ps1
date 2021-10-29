$ErrorActionPreference = "SilentlyContinue"
#Get Migration Batches
Write-Host "Gathering Migration Batches" -ForegroundColor Green
$migBatches = Get-MigrationBatch
$migBatches

#Sort Pictures by Migration Batch
Write-Host "Sorting Pictures based on Migration Batch" -ForegroundColor Green
$migBatches | foreach {
    $directory = New-Item -Name $_.Identity -ItemType Directory
    $batchUsers = Get-MigrationUser -BatchId $_.Identity.name
    $batchUsers = $batchUsers.Identity
    $batchUsers = $batchUsers -replace "@aeci.org",".jpg"
    foreach ($user in $batchUsers) 
        {
        $photo = Get-Item C:\Temp\Profiles\$user -ErrorAction SilentlyContinue
        Copy-Item $photo $directory -Verbose -ErrorAction SilentlyContinue
        }
    }
$ErrorActionPreference = "Continue"
#Go to Each Directory, and upload user Photos
Write-Host "Setting User Photos" -ForegroundColor Green
$directories = ls | where {$_.Mode -eq "d-----"}
$directories | foreach {
    #Enter each Directory and Gather User Photos
    Write-Host $_ -ForegroundColor Magenta
    cd $_
    $userphotos = ls *.jpg

    #Start Foreach Loop
    foreach ($photo in $userphotos)
        {

        #Rename each name as the proper Email Address
        $mailbox = $photo.Name -replace ".jpg","@aeci.org"

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
    cd ..
    }

