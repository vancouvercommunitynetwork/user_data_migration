# User data extraction and migration

## Usage:
### ./extractUserData.sh user_name_here
### ./createUser.sh NOTE: USE ON THE OTHER SIDE

##Info

### extractUserData.sh
#### Infos
- Will extract user info and their ecrypted password into 2 files (Default Names): "output.txt" and "pass.txt"
- Will check if these 4 exist (not empty string - moddable in the file): file,passwd_file=,remoteHost and des\_directory
	- If either is empty it will exit the program without doing anything
	- file is the user details output file name
	- passwd_file is file contains the users and their encrypted password
	- remoteHost is where the files will copy into
	- des_directory is where the folder in the remote host

#### Programe Procedure
- Will check if the 4 requirement exist: file,passwd_file=,remoteHost and des\_directory
- Then check if user exist
- Once all the checks pass it will do the extraction
- If a replaceable string exist it will do the replacement
- Output to a file

#### Functions
- extractDetails will extract User data then save it into a file
- extractPassword will extract the User's password then save it into a file
- checkingThings will check if a replaceable string exist 
- checkMissingRequirements will check if these 4 exists: file,passwd_file=,remoteHost and des\_directory
- isUserExist will check if user exist


### createUser.sh
#### Info:
- Will check if both user file and password file exist under checkingFileExitance function
- If both exist then it will create users then change their password into their encrypted password
- After creation, both files will delete to avoid creating same users


#### Functions:
- checkingFileExitance will check if the user_file and password\_file exist (both change able in the script)
- createUser will create users in a batch then change the password in a batch as well
- deleteFiles will delete both user_file and password\_file within the directory (if it exist then it's deletable)


