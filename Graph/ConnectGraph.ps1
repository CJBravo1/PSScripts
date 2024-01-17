#Check if Microsof.Graph and Azure Powershell Module are Installed.
if ($null -eq (Get-InstalledModule microsoft.graph -ErrorAction SilentlyContinue))
    {
        Write-Host "Installing Microsoft Graph Powershell Modules" -ForegroundColor Green
        Install-Module Microsoft.Graph -Scope CurrentUser -Verbose
    } 
    #if  ($null -eq (Get-InstalledModule Az -ErrorAction SilentlyContinue))
    #{
        #Write-Host "Installing Azure Powershell Module" -ForegroundColor Green
        #Install-Module az -Scope CurrentUser -Verbose
    #}
    #Check for current Graph Connections
    $MGContext = Get-MgContext
    if ($null -eq $MGContext)
    {
       $Write =  Read-Host "Read or Write?"
        switch ($write)
        {
            "Write"
            {
                Connect-MgGraph -Scopes 'Directory.ReadWrite.All','User.ReadWrite.All','Group.ReadWrite.All','LicenseService.ReadWrite.All','User.Export.All','User.Read.All','Directory.AccessAsUser.All','User.ReadBasic.All','Directory.Read.All'
            }
            "Read"
            {
                Connect-MgGraph -Scopes 'User.Read.All', 'Directory.AccessAsUser.All', 'User.ReadBasic.All', 'User.ReadWrite.All', 'Directory.Read.All', 'Directory.ReadWrite.All', 'Group.Read.All', 'User.Export.All', 'LicenseService.Read.All'
            }
            
        }
    }
    else 
    {
        Write-Host "Currently Connected as "$MGContext.Account -ForegroundColor Green
        $MGContext.Scopes
        Write-Host "Use Disconnect-MGGraph to Sign Out..." -ForegroundColor Red
    }

    #Output Connection Information
    $MgDomains = Get-MgDomain
    $DefaultMgDomain = $MgDomains | Where-Object {$_.IsDefault -eq $true}
    $DefaultMgDomain.Id 
    $MGContext.Account
    $mgContext | Select-Object -ExpandProperty scopes
