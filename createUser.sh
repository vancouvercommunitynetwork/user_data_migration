dest_directory="/home/vcn"
user_file="$dest_directory/output.txt"
pass_file="$dest_directory/pass.txt"

createUser(){
    $(newusers -r $user_file)
    chpasswd -e < $2
}

checkIfFileExists(){
	if [ ! -f $user_file ]
	then
		echo "User File not found!"
		exit
	fi
	if [ ! -f $pass_file ]
	then
		echo "Password File not found!"
		exit
	fi
}

deleteFile(){
	rm $user_file
	rm $pass_file
}

checkIfFileExists		
createUser $user_file $pass_file
deleteFile $user_file $pass_file

