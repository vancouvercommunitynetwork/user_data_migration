#changeable but must exist
user_info_file="output.txt"
user_passwd_file="pass.txt"
remoteHost="ryancua@192.168.20.130"
des_directory="/home/ryancua"
directory_files="users_dir_file.txt"
des_file="$des_directory/createUser.sh"

copy_to_remote(){

rsync -za "$user_info_file" "$remoteHost":"$des_directory"
rsync -za "$user_passwd_file" "$remoteHost":"$des_directory"
rsync -za "createUser.sh" "$remoteHost":"$des_directory"
ssh "$remoteHost" . "$des_file"


while IFS='' read -r line || [[ -n "$line" ]]; do	
	rsync -za "$line" "$remoteHost":"/home/"
done < "$directory_files"


}

copy_to_remote


