# An alternate version extractUserData.sh

# For each name in $1 (the user list input)
#   grep name in /etc/passwd
#   breakdown grep result into user fields
#   output the user fields into a new line in the output file

# Indices of data members in an /etc/passwd entry.
index_user=0
index_password=1
index_uid=2
index_gid=3
index_gecos=4
index_dir=5
index_shell=6

# Construct array of all /etc/passwd entries that match any of the users listed in $1
echo "Processing user list: $1"
user_result=$(grep "^$1:" /etc/passwd) # Entry line must start with username followed by a colon in order to match.
IFS=':' read -r -a array_of_entry_data <<< "$user_result"

entry_user=${array_of_entry_data[index_user]}
entry_password=${array_of_entry_data[index_password]}
entry_uid=${array_of_entry_data[index_uid]}
entry_gid=${array_of_entry_data[index_gid]}
entry_gecos=${array_of_entry_data[index_gecos]}
entry_dir=${array_of_entry_data[index_dir]}
entry_shell="nologin"  # Disable shell access.

user_entry="$entry_user:$entry_password:$entry_uid:$entry_gid:$entry_gecos:$entry_dir:$entry_shell"

user_data_output="user_data_output.txt"

echo $user_entry > $user_data_output


