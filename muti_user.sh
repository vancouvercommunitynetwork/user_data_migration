#changeable
list_of_users_file="list_of_users.txt"
#changeable, but not recommanded
remote_file="rsyncing_stuff.sh"

launchingProgram(){

while IFS='' read -r line || [[ -n "$line" ]]; do
	. extractUserData.sh "$line"
done < "$list_of_users_file"

}


if [ ! -f $list_of_users_file ]                #does file exist?
then
	echo 'no file'
	exit
	
else	
	launchingProgram
	. $remote_file
fi



