ForEach ($folder in (get-mailpublicfolder -ResultSize Unlimited | Where-Object{$_.alias -match ‘\s’}))

{
#check for a space
if ($folder.alias -match ‘\s’)
{
#determine new alias
$newAlias = $folder.WindowsEmailAddress.replace(“@domain.com”,””)
$newAlias = $newAlias -replace ‘\s|,|\.|\-‘;$_

#resize long PF aliases to below 32 characters
if($newAlias.Length -gt 31) { $newAlias = $newAlias.Substring(0,31)}

#rename PF alias
Set-MailPublicFolder -Identity $folderObject.WindowsEmailAddress -Alias $newAlias
}
}