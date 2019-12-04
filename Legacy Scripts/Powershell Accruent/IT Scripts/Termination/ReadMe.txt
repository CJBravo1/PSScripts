# TermScript.ps1
# Created: 5/8/2017

INPUT: Script reads from TermedUsers.csv (located in same folder as script and this read me)
       The CSV should be filled out with the username, termdate, and product line for each user
       you wish to be terminated.

DESCRIPTION : This script is for removing the various forms of access for former Accruent employees
This script will
 1) Log in to Office 365
 2) Set the termed user's mailbox to forward to their manager
 3) Update the "\\FS02\Departments\IT\Disabled_Exchange_Accounts.xlsx" to reflect the new forwarding address
 4) Save a list of the AD groups the user was a member of as a csv to "\\accruent.com\fs\Departments\IT\Groups\$AccName - Groups.csv"
 5) Disable the user's AD account
 6) Append a "zzz" to the front of the user's name
 7) Add the user to the "Disabled" group
 8) Remove the user from all other AD groups
 9) Send an email to "itopsmgmt" "servicedesk" and "infrastructure" with the list from part 4)
 10) Submit a KACE ticket for collecting and backing up the computer
 11) Submit a KACE ticket to facilities
 12) Email the corresponding product's hosting and support teams
 13) Open the following websites 
	- https://www.dropbox.com/home
	- https://login.microsoftonline.com/
	- https://accruent.webex.com/mw3100/mywebex/default.do?siteurl=accruent
	- https://www.tcconline.com/IOL.action
	- http://portal.thevoicemanager.com/Login.aspx
 14) Open the Software Inventory sheet "C:\Dropbox (Accruent)\IT\Software Inventory.xlsx"
 15) Sync with the closest domain controller
 16) BosCorpAADC to Office365 sync

OUTPUT: 
	- Checks if user is the worksheet from step 3) Output appropriate message either way
	- Prompt for user input if a manager cannot be found in AD properties
	- Output the user's Username, Name, Title, Term Date, Manager, Manager's email for each termed user
	- Output results of syncing with the domain controller