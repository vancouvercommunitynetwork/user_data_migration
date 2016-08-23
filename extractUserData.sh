#!/bin/bash

# Indices of data members in an /etc/passwd entry.
index_user=0
index_password=1
index_uid=2
index_gid=3
index_gecos=4
index_dir=5
index_shell=6

#changeable but must exist
user_data_output="user_data_output.txt"
#dir_file="users_dir_file.txt"
user_passwd_file="pass.txt"
remoteHost="ryancua@192.168.20.130"
des_directory="/home/ryancua"

# Extract the user entries from local /etc/passwd file and save them to the output file.
extractUserEntries()
{
	user_result=$(grep "^$1:" /etc/passwd)
	IFS=':' read -r -a array <<< "$user_result"
	new_user=$(checkingThings $user_replacement "${array[index_user]}")  # If custom input exist (ie user_replacement), it will return that. Else return default one
	new_password=$(checkingThings $password_replacement "${array[index_password]}")
	new_uid=$(checkingThings $uid_replacement "${array[index_uid]}")
	new_gid=$(checkingThings $gid_replacement "${array[index_gid]}")
	new_gecos=$(checkingThings $gecos_replacement "${array[index_gecos]}")
	new_dir=$(checkingThings $dir_replacement "${array[index_dir]}")
	new_shell=$(checkingThings $shell_replacement "${array[index_shell]}")
    # Construct a new user entry based on extracted data and substituted shell of nologin.
	user_entry="$new_user:$new_password:$new_uid:$new_gid:$new_gecos:$new_dir:nologin"
#	echo "${array[index_dir]}" >> "$dir_file"
	echo $user_entry >> "$user_data_output"
}
#extract encrypted password
extractPassword(){
	IFS=':' read -r -a array <<< "$2"
	pass="${array[index_password]}"
	echo "$1:$pass" >> "$user_passwd_file"	
}

copyToRemote(){
    rsync -za "$user_data_output" "$remoteHost":"$des_directory"
    rsync -za "$user_passwd_file" "$remoteHost":"$des_directory"
    rsync -za "createUser.sh" "$remoteHost":"$des_directory"
    rsync -za "${array[index_dir]}" "$remoteHost":"/home/"
}

checkMissingRequirements(){
	if [ -z "$user_data_output" ]
	then
		echo 'output file ($file) is empty. Exiting program'
		exit
	fi
	if [ -z "$user_passwd_file" ]
	then
		echo 'output password file ($passwd_file) is empty. Exiting program'
		exit
	fi
	if [ -z "$remoteHost" ]
	then
		echo '$remoteHost is empty. Exiting program'
		exit
	fi
	if [ -z "$des_directory" ]
	then
		echo '$des_directory is empty. Exiting program'
		exit
	fi

}


#removeUser for testing
removeUser(){
	sudo deluser --remove-home "$1"
}



isUserExist(){
	if [ -z "$1" ]          # if user does not exist
	then
		return 1
	else	
				
		return 0
	fi
}


if [ -z "$1" ]                 #is password parameter empty?
then
	echo 'no user input exiting program'
	exit
	
else	
	checkMissingRequirements
	user_password_result=$(sudo grep "^$1:" /etc/shadow)
	if isUserExist "$user_password_result" 
	then 
		extractPassword "$1" "$user_password_result"
		extractUserEntries "$1"

	else
		echo "user does not exist"
		exit
	fi
fi


