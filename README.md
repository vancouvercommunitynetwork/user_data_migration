# User data extraction and migration

## Usage:
### ./extractUserData.sh user_name_here
### ./createUser.sh NOTE: EXECUTE IT ON THE REMOTE SIDE

##Info
### Steps:
	- First make sure you the mod can access both files (assuming you are root):
		- do this: chown root:root /opt/user_data_migration/extractUserData.sh
		- or sudo chmod 700 /opt/user_data_migration/createUser.sh
	- Run ./extractUserData.sh "user_name_here"
	- Make sure you have access to remote host, it will ask for your password while executing extractUserData.sh
	- Goto remote host then make a cron job file call user_creation in /etc/cron.d:
		- Inside the file type this:  * * * * * root ./opt/user_data_migration/createUser.sh
### extractUserData.sh
#### Infos
- Will extract user info and their ecrypted password into 2 files (Default Names): "output.txt" and "pass.txt"
- Will check if these 4 exist (not empty string - changeable in the file): file, passwd_file, remoteHost and des\_directory
	- If either is empty it will exit the program without doing anything
	- file is the user details output file name
	- passwd_file is file contains the users and their encrypted password
	- remoteHost is where the files will copy into
	- des_directory is where the folder in the remote host

#### Programe Procedure
- Will check if the 4 requirement exist: file, passwd_file, remoteHost and des\_directory
- Then check if user exist
- Once all the checks pass it will do the extraction
- If a replaceable string exist it will do the replacement
- Output to a file
- Copy both output files and createUser.sh (in case if createUser.sh is not there) to remote host

#### Functions
- extractDetails will extract User data then save it into a file
- extractPassword will extract the User's password then save it into a file
- checkingThings will check if a replaceable string exist 
- checkMissingRequirements will check if these 4 exists: file, passwd_file, remoteHost and des\_directory
- isUserExist will check if user exist
- copyToRemote will copy the output files and createUser.sh to remote host


### createUser.sh
#### Info:
- Will check if both user file and password file exist under checkingFileExitance function
- If both exist then it will create users then change their password into their encrypted password
- After creation, both files will delete to avoid creating same users


#### Functions:
- checkingFileExitance will check if the user_file and password\_file exist (both change able in the script)
- createUser will create users in a batch then change the password in a batch as well
- deleteFiles will delete both user_file and password\_file within the directory (if it exist then it's deletable)


