MailServer = "DIGSMXPF1"
Mailbox = "ExchTestTD"
Const PR_FREEBUSY_ENTRYIDS = &H36E41102
Const PR_PARENT_ENTRYID = &H0E090102
Const PR_RECALCULATE_FREEBUSY = &H10F2000B 
Const PR_FREEBUSY_DATA = &H686C0102 
report = "<table border=""1"" width=""100%"">" & vbcrlf
report = report & "  <tr>" & vbcrlf
report = report & "<td align=""center"" bgcolor=""#000080""><b><font color=""#FFFFFF"">Mailbox-Name</font></b></td>" & vbcrlf
report = report & "<td align=""center"" bgcolor=""#000080""><b><font color=""#FFFFFF"">Auto Process Meetings</font></b></td>" & vbcrlf
report = report & "<td align=""center"" bgcolor=""#000080""><b><font color=""#FFFFFF"">Auto Decline conflicts</font></b></td>" & vbcrlf
report = report & "<td align=""center"" bgcolor=""#000080""><b><font color=""#FFFFFF"">Auto Decline recurring</font></b></td>" & vbcrlf
report = report & "</tr>" & vbcrlf

set objSession = CreateObject("MAPI.Session")
strProfile = MailServer & vbLf & Mailbox
objSession.Logon "",,, False,, True, strProfile
Set objInfoStores = objSession.InfoStores
set objInfoStore = objSession.GetInfoStore
Set objpubstore = objSession.InfoStores("Public Folders")
Set objRoot = objInfoStore.RootFolder 

set non_ipm_rootfolder = objSession.getfolder(objroot.fields.item(PR_PARENT_ENTRYID),objInfoStore.id)
fbids = non_ipm_rootfolder.fields.item(PR_FREEBUSY_ENTRYIDS).value
set publicfbusy = objSession.getmessage(fbids(2),objpubstore.id)
set publicfbusyfold = objSession.getfolder(publicfbusy.fields.item(PR_PARENT_ENTRYID),objpubstore.id)
on error resume next
for each fbmess in publicfbusyfold.messages
	wscript.echo fbmess.subject
	wscript.echo "Automatically accept meeting and process cancellations : " & fbmess.fields.item(&H686D000B)
	wscript.echo "Automatically decline conflicting meeting requests : " & fbmess.fields.item(&H686F000B)
	wscript.echo "Automatically decline recurring meeting requests : " & fbmess.fields.item(&H686E000B)
	wscript.echo
	if err.number <> 0 then
		err.clear
	else
		if fbmess.fields.item(&H686D000B).value = true then
			report = report & "<tr>" & vbcrlf
			report = report & "<td align=""center"">" & fbmess.subject & "&nbsp;</td>" & vbcrlf
			report = report & "<td align=""center"">" & fbmess.fields.item(&H686D000B) & "&nbsp;</td>" & vbcrlf
			report = report & "<td align=""center"">" & fbmess.fields.item(&H686F000B) & "&nbsp;</td>" & vbcrlf
			report = report & "<td align=""center"">" & fbmess.fields.item(&H686E000B) & "&nbsp;</td>" & vbcrlf
			report = report & "</tr>" & vbcrlf
		end if
	end if
next
report = report & "</table>" & vbcrlf
Set fso = CreateObject("Scripting.FileSystemObject")
set wfile = fso.opentextfile("c:\temp\DOBreport.htm",2,true) 
wfile.write report
wfile.close
set wfile = nothing
set fso = nothing


