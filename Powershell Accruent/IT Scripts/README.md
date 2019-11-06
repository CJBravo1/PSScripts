# README #

This README would normally document whatever steps are necessary to get your application up and running.

### What is this repository for? ###

* This repo is for the powershell scripts created by the Corporate IT team
* most of these perform administrative task in Active Directory or Office 365
* Branching is disabled in this repository
* NEVER store passwords in plaintext in a script

### How do I get set up? ###

* 1. Install Git (the version control software) https://git-scm.com/download/win
* 2. Clone the repo to your local machine. Navigate to the desired directory and run the command
*       git clone https://<username>@bitbucket.org/accruent/it_scripts.git

### To add files ###

* 1. Git add newfile.txt
* 2. git commit -m "message text here" (If you forget the message and get stuck in the vi editor, exit and save with :wq)
* 3. git push origin master (push the changes to the master branch)This command specifies that you are pushing to the master branch (the branch on Bitbucket) on origin (the Bitbucket server). 

### To revert back to previous commits ###
* 1. Look up the commit number (usually through the online repo)
* 2. Run git status to check for any uncommitted changes
* 3. Use the command git reset --hard <commit number> (this will remove any uncommitted changes)


### Get latest version of code ###
* Always make sure you are up to date before you begin editing code by using the command
  git pull --all
  
### Who do I talk to? ###

* Regan Vecera and Josh Batson are administrators of this repository