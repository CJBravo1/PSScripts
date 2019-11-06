$ts = Get-Date -Format yyyyMMdd_hhmmss
$FormatEnumerationLimit = -1
Start-Transcript EXOnline$ts.txt
Get-IntraOrganizationConfiguration | fl
Get-IntraOrganizationConnector | fl
Get-AuthServer -Identity 00000001-0000-0000-c000-000000000000 | fl
Get-PartnerApplication | fl
Test-OAuthConnectivity -Service EWS -TargetUri OnPremises External EWSurl: https://webmail.aeci.org/ews/exchange.asmx> -Mailbox testuser1@aeci.org -Verbose | fl
Test-OAuthConnectivity -Service AutoD -TargetUri OnPremises Autodiscover.svc endpoint: https://webmail.aeci.org/autodiscover/autodiscover.svc -Mailbox testuser0@aeci.org -Verbose | fl
Get-Mailbox testuser0@aeci.org | fl
Get-MailUser testuser1@aeci.org |fl
Get-OrganizationRelationship | fl
Stop-Transcript