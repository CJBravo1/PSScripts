# Set the path to your directory containing the CSV files
$directoryPath = "C:\Path\To\Directory"

# Get all CSV files in the directory
$csvFiles = Get-ChildItem -Path $directoryPath -Filter "*.csv"

# Create an empty array to store the data from all CSV files
$allData = @()

# Loop through each CSV file
foreach ($csvFile in $csvFiles) {
    # Read the content of the current CSV file
    $data = Import-Csv $csvFile.FullName

    # Add a new column with the name of the CSV file
    $data | Add-Member -MemberType NoteProperty -Name "DistributionList" -Value $csvFile.Name -Force

    # Append the data to the $allData array
    $allData += $data
}

# Merge all data into a single CSV file
$allData | Export-Csv -Path "C:\Path\To\Directory\MergedOutput.csv" -NoTypeInformation
