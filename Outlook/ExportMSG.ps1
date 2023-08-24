# Set the current working directory as the export path
$ExportPath = (Get-Location).Path

# Load Outlook COM object
$Outlook = New-Object -ComObject Outlook.Application

# Access the Inbox folder
$Namespace = $Outlook.GetNamespace("MAPI")
$Inbox = $Namespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderInbox)

# Function to recursively export messages with folder structure
function Export-Messages ($folder, $destination) {
    foreach ($Item in $folder.Items) {
        if ($Item -is [Microsoft.Office.Interop.Outlook.MailItem]) {
            try {
                $MsgFile = $destination + "\" + $Item.Subject + ".msg"
                $Item.SaveAs($MsgFile, [Microsoft.Office.Interop.Outlook.OlSaveAsType]::olMSG)
            } catch {
                Write-Host "Error exporting message: $($_.Exception.Message)"
            }
        }
    }

    foreach ($Subfolder in $folder.Folders) {
        $SubfolderPath = $destination + "\" + $Subfolder.Name
        if (!(Test-Path -Path $SubfolderPath)) {
            New-Item -Path $SubfolderPath -ItemType Directory | Out-Null
        }
        Export-Messages $Subfolder $SubfolderPath
    }
}

# Function to create folder structure
function Create-Folder-Structure ($folder, $destination) {
    foreach ($Subfolder in $folder.Folders) {
        $SubfolderPath = $destination + "\" + $Subfolder.Name
        if (!(Test-Path -Path $SubfolderPath)) {
            New-Item -Path $SubfolderPath -ItemType Directory | Out-Null
        }
        Create-Folder-Structure $Subfolder $SubfolderPath
    }
}

# Start exporting messages with folder structure
Create-Folder-Structure $Inbox $ExportPath
Export-Messages $Inbox $ExportPath

# Release resources
$Namespace = $null
$Outlook.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null
