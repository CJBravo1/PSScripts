Import-Module Microsoft.Graph.Users.Actions
$EmailTo = "example@domain.com"
$EmailFrom = "example@domain.com"

$params = @{
    Message = @{
        Subject = "Example Message?"
        Body = @{
            ContentType = "Text"
            Content = "This is an example Message."
        }
        ToRecipients = @(
            @{
                EmailAddress = @{
                    Address = $EmailTo
                }
            }
        )
    }
}
# A UPN can also be used as -UserId.
Send-MgUserMail -UserId $EmailFrom  -BodyParameter $params