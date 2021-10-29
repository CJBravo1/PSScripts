#Get Credentials
$CurrentUser = $env:USERNAME
$CurrentUser = Get-ADUser -Identity $env:USERNAME -Properties EmailAddress
$FromADEmail = $CurrentUser.EmailAddress
$FromADName = $CurrentUser.DisplayName
$MailRelayServer = "smtp.DOMAIN.local"

if ($null -eq $adminCreds)
{
    $adminCreds = Get-Credential "DOMAIN\$CurrentUser"
}

#Check for Team PSSession
$TeamsModule = Get-Module MicrosoftTeams
if ($null -eq $TeamsModule)
{
    Install-Module -Name MicrosoftTeams -RequiredVersion 1.1.6
}

$DOMAINTeam = Get-Team -GroupId f59a5da7-159b-4a93-92b7-0541e9a364d4
if ($null -ne $DOMAINTeam)
{
    #Get New Team Name
    $TeamNameInput = Read-Host "Enter New Team Name"
    $TeamOwnerInput = Read-Host "Enter New Team Owner"
    if ($TeamOwnerInput -like "*@DOMAIN.com")
        {
            Write-Host "Correcting Input" -ForegroundColor Yellow
            $TeamOwnerInput = $TeamOwnerInput.Replace("@DOMAIN.com","")
        }
    $TeamVisabilityInput = Read-Host 'Public or Private Team?'

    switch ($TeamVisabilityInput) 
    {
        "Public" {$TeamVisability = "Public"}
        "Private" {$TeamVisability = "Private"}
        Default {$TeamVisability = "Public"}
    }

    #Get Owner AD Record
    $TeamOwner = Get-ADUser -Identity $TeamOwnerInput -Properties EmailAddress
    $TeamOwnerEmail = $TeamOwner.EmailAddress
    $TeamOwnerDisplayName = $TeamOwner.DisplayName
    #Check for Original Name
    if ($null -eq (Get-Team -DisplayName $TeamNameInput) -and $null -ne $TeamOwner)
    {
        #Create New Team
        Write-Host "Creating $TeamNameInput Team" -ForegroundColor Green
        $NewTeam = New-Team -DisplayName $TeamNameInput -Owner $TeamOwnerEmail -AllowGuestCreateUpdateChannels $false -AllowGuestDeleteChannels $false -AllowAddRemoveApps $false -AllowCreateUpdateRemoveConnectors $false -ShowInTeamsSearchAndSuggestions $false -Visibility $TeamVisability
        $NewTeam

        #Send EMail to Team Owner
        if ($null -ne $NewTeam)
            {
                $EmailMessage = "
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>Hello $TeamOwnerDisplayName,</p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>Your Team $TeamNameInput has been created, with you set as the owner. </p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>You can add members to your team by clicking on the 'Triple Dots' next to your new team, and selecting 'Add Member'.</p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>&nbsp;</p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>If you need a large amount of members to this team, please reply with the members you need added. </p
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>&nbsp;</p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>Thanks</p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>&nbsp;</p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'>&nbsp;</p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'><strong><span style='font-size:13px;font-family:'Arial',sans-serif;'>$FromADName | Corporate Applications | DOMAIN LLC</span></strong></p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'><span style='font-size:13px;font-family:'Arial',sans-serif;color:#1F497D;'>&nbsp;</span></p>
                <p style='margin:0in;margin-bottom:.0001pt;font-size:15px;font-family:'Calibri',sans-serif;'><span style='font-size:12px;font-family:'Arial',sans-serif;'>Connect with us:<span style='color:#1F497D;'>&nbsp;</span></span><a href='https://twitter.com/DOMAIN'><span style='font-size:12px;font-family:'Arial',sans-serif;color:#0563C1;'>Twitter</span></a><span style='font-size:12px;font-family:'Arial',sans-serif;color:#0563C1;'>&nbsp;</span><span style='font-size:12px;font-family:'Arial',sans-serif;color:#2F5496;'>|&nbsp;</span><a href='https://www.linkedin.com/company/DOMAIN-llc'><span style='font-size:12px;font-family:'Arial',sans-serif;color:#0563C1;'>LinkedIn</span></a><span style='font-size:12px;font-family:'Arial',sans-serif;color:#0563C1;'>&nbsp;</span><span style='font-size:12px;font-family:'Arial',sans-serif;color:#2F5496;'>|</span><span style='font-size:12px;font-family:'Arial',sans-serif;color:#0563C1;'>&nbsp;</span><a href='https://www.facebook.com/DOMAIN'><span style='font-size:12px;font-family:'Arial',sans-serif;color:#0563C1;'>Facebook</span></a><span style='font-size:12px;font-family:'Arial',sans-serif;color:#2F5496;'>&nbsp;</span><span style='font-size:12px;font-family:'Arial',sans-serif;color:#2F5496;'>|&nbsp;</span><a href='http://www.youtube.com/DOMAINTV'><span style='font-size:12px;font-family:'Arial',sans-serif;color:#0563C1;'>YouTube</span></a></p>"
    
                Write-Host "Sending New Team Email to $TeamOwnerEmail" -ForegroundColor Green
                Send-MailMessage -To $TeamOwnerEmail -From $FromADEmail -Bcc $FromADEmail -Subject "Your New Team Has Been Created" -Body $EmailMessage -BodyAsHtml -SmtpServer $mailRelayServer  -Credential $adminCreds 
            }
    }

    else {Write-Host "$TeamNameInput Currently Exists!" -ForegroundColor Yellow -BackgroundColor Red}
}
else {Connect-MicrosoftTeams -Credential $adminCreds}
