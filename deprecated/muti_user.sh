#changeable
list_of_users_file="list_of_users.txt"
#changeable, but not recommanded
remote_file="rsyncing_stuff.sh"
user_info_file="output.txt"
dir_file="users_dir_file.txt"
user_passwd_file="pass.txt"


launchingProgram(){

while IFS='' read -r line || [[ -n "$line" ]]; do
	./extractUserData.sh "$line"
done < "$list_of_users_file"

}


if [ ! -f $list_of_users_file ]                #does file exist?
then
	echo 'no file'
	exit
	
else	
	echo -n "" > "$dir_file"
	echo -n "" > "$user_info_file"
	echo -n "" > "$user_passwd_file"
	launchingProgram
	./$remote_file


fi



