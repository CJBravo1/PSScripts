This script is for creating a Contractor Accounts in ADUC.

How do you use it?
-Fill out Contractor.csv. This is where the script will pull the user info from. 
-Enter in the relevant user's information, then save and close. 

-FirstName
-LastName
-Department
-Manager
-Company

-From this directory. Right-click on "Contractor Account Creation", and select "Run with PowerShell".
-Let it run. You will get an email confirmation (if successful), with the user's Name, Username, and Email address. 
-Verify the information has been entered properly. 
-Go to our Office365 admin portal, and assign the user an E1 license. 
-Email the Contractor's Accruent manager with the user's credentials.
-All done. 

WHAT IT DO:
-Sets variables.
-Creates user account.
-Sets Name, Email Address, UPN, Description, Title, Department, Company
-Sets Proxy and Target Adresses for O365.
-Replicates out to domain controllers.
-Syncs with BosCorpAADC.
-All done. 