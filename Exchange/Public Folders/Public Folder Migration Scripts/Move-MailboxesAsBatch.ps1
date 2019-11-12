<#
    .SYNOPSIS
    Move Exchange mailboxes as batch
   
   	Thomas Stensitzki
	
	THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
	RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
	Version 1.2, 2015-09-18

    Ideas, comments and suggestions to support@granikos.eu 
 
    .LINK  
    More information can be found at http://www.granikos.eu/en/scripts 
    More details on New-Migrationbatch at https://technet.microsoft.com/en-us/library/jj219166(v=exchg.150).aspx
	
    .DESCRIPTION
	
    This script moves Exchange mailboxes as batch to a new target database. The batch is created using a CSV file containing a single column "EmailAddress"
    Additional columns used for other migration purposes are ignored.

    .NOTES 
    Requirements 
    - Windows Server 2012 R2  
    - GlobalFunctions available and configured $env:PSModulePath
    - Exchange Server 2013 Management Shell

    Revision History 
    -------------------------------------------------------------------------------- 
    1.0     Initial community release 
    1.1     AutoStart switch added
    1.2     AutoComplete /w non AutoStart added
	
	.PARAMETER CSVFile
    Import CSV file containing mailbox email addresses. Required CSV column name "EmailAddress"

    .PARAMETER BadItemLimit
    Bad Item Limit for mailbox migration
    Default = 0

    .PARAMETER AutoComplete
    Switch to enable automatic completion of the migration batch after sync

    .PARAMETER AutoComplete
    Switch to enable automatic startof the migration batch

    .PARAMETER NotificationEmails
    The NotificationEmails parameter specifies one or more email addresses that migration status reports are sent to. Specify the value as a string array, and separate multiple email addresses with commas.

    .PARAMETER RepositoryFolder
    Folder for successfully started CSV files. CSV files will be copied after migration batch has been created successfully
    Default = ConfiguredBatches

	.EXAMPLE
    Migrate users configured in in CSV file MyBatchFile.csv and complete migration automatically
    .\Move-MailboxesAsBatch.ps1 -CSVFile .\MyBatchFile.csv -AutoComplete

	.EXAMPLE
    Migrate users configured in in CSV file MyBatchFile.csv, allow 10 bad item, notify it@mcsmemail.de and do not complete migration automatically
    .\Move-MailboxesAsBatch.ps1 -CSVFile .\MyBatchFile.csv -BadItemLimit 10 -NotificationEmails @("it@mcsmemail.de")

    #>
Param(
    [parameter(Mandatory=$true,ValueFromPipeline=$false,HelpMessage='Full path to CSV file')][string]$CSVFile,  
    [parameter(Mandatory=$false)][int]$BadItemLimit=0,
    [parameter(Mandatory=$false)][switch]$AutoComplete,
    [parameter(Mandatory=$false)]$NotificationEmails=@("ExchangeAdmin@mcsmemail.de"),
    [parameter(Mandatory=$false)][string]$RepositoryFolder="ConfiguredBatches",
    [parameter(Mandatory=$false)][switch]$AutoStart      
)

Set-StrictMode -Version Latest

Import-Module GlobalFunctions
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ScriptName = $MyInvocation.MyCommand.Name
$logger = New-Logger -ScriptRoot $ScriptDir -ScriptName $ScriptName -LogFileRetention 14
$logger.Write("Script started")

$sleep = 60 # sleep 60 seconds

# MAIN #############################

if(Test-Path $CSVFile) {
    $logger.Write("Validating CSV file $($CSVFile)")

    # Import CSV file
    $CSVData = Import-Csv -Path $CSVFile -Delimiter ","

    $test = $null
    try {
        # Test, whether there the required CSV column EmailAddress exists and contains data
        $test = $CSVData[0].EmailAddress
    }
    catch {}

    if($test -ne $null) {

        $CSV = $CSVData | Measure-Object # if only one data row exists, the data object does not provide a .COUNT property

        # Some output for the lazy Exchange Administrator
        Write-Host "CSV File $($CSVFile) contains $($CSV.Count) row(s) of data"

        $FullPath = Resolve-Path $CSVFile

        $BatchName = ([io.path]::GetFileNameWithoutExtension($FullPath)).ToUpper()  #(Split-Path -Path $CSVFile -Leaf).ToUpper()
        Write-Host "Batch will be created as follows"
        Write-Host "Name              : $($BatchName)"
        Write-Host "BadItemLimit      : $($BadItemLimit)"
        Write-Host "NotificationEmails: $($NotificationEmails)"
        Write-Host "AutoStart         : $($AutoStart)"
        Write-Host "AutoComplete      : $($AutoComplete)"
        Write-Host "Resolved CSV Path : $($FullPath)"

        $logger.Write("Create Batch $($BatchName) [AutoStart: $($AutoStart), AutoComplete: $($AutoComplete), BadItemLimit: $($BadItemLimit), NotificationEmails: $($NotificationEmails), CSV: $($FullPath)]")

        try {
            if($AutoComplete -and $AutoStart) {
                # Create Migration Batch without a dedicated target mailbox database, automatic start and automatic complete
                New-MigrationBatch -Local -Name $BatchName -CSVData ([System.IO.File]::ReadAllBytes($FullPath)) -AllowUnknownColumnsInCsv $true -NotificationEmails $NotificationEmails -BadItemLimit $BadItemLimit -AutoStart -AutoComplete -ErrorAction Stop | Out-Null 
            }
            elseif ($AutoStart) {
                # Create Migration Batch without a dedicated target mailbox database, automatic start and NO automatic complete
                New-MigrationBatch -Local -Name $BatchName -CSVData ([System.IO.File]::ReadAllBytes($FullPath)) -AllowUnknownColumnsInCsv $true -NotificationEmails $NotificationEmails -BadItemLimit $BadItemLimit -AutoStart -ErrorAction Stop | Out-Null 
            }
            elseif ($AutoComplete) {
                # Create Migration Batch without a dedicated target mailbox database, automatic complete
                New-MigrationBatch -Local -Name $BatchName -CSVData ([System.IO.File]::ReadAllBytes($FullPath)) -AllowUnknownColumnsInCsv $true -NotificationEmails $NotificationEmails -BadItemLimit $BadItemLimit -AutoComplete -ErrorAction Stop | Out-Null                 
            }
            else {
                # Create Migration Batch without a dedicated target mailbox database, NO automatic start and NO automatic complete
                New-MigrationBatch -Local -Name $BatchName -CSVData ([System.IO.File]::ReadAllBytes($FullPath)) -AllowUnknownColumnsInCsv $true -NotificationEmails $NotificationEmails -BadItemLimit $BadItemLimit -ErrorAction Stop | Out-Null 
            }

            Write-Host "Wait $($sleep) seconds"
            Start-Sleep -Seconds $sleep

            # Check, if migration batch has been created
            $batch = Get-MigrationBatch $BatchName 
            if($batch -ne $null) {
                Write-Host "Migration Batch $($BatchName) created containing $($batch.TotalCount) mailboxes"
                $logger.Write("Migration Batch $($BatchName) created containing $($batch.TotalCount) mailboxes")

                # Copy CSV to sub folder
                $logger.CopyFile($FullPath, $RepositoryFolder)
            } 
            else {
                # Ooops, batch not found.
                Write-Host "Migration Batch $($BatchName) not found. Please check Exchange manually." 
                $logger.Write("Migration Batch $($BatchName) not found. Please check Exchange manually.",2)
            }
        }
        catch {
            # Opps, something happend
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
            $logger.Write($ErrorMessage,1)
        }

    }
    else {
        # Ooops, Something went wrong with CSV
        Write-Error "CSV file $($CSVFile) does NOT contain a column EmailAddress. Please check the CSV file."
        $logger.Write("Script aborted. CSV file $($CSVFile) does NOT contain a column EmailAddress.", 1)
    }
}

# Finished
$logger.Write("Script finished")