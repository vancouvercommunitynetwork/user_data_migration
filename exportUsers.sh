#!/bin/bash

# TO DO:
#   Check that the destination is reachable.
#   Check that file copying succeeds before attempting newusers and chpasswd (maybe the files couldn't be created for permission reasons or maybe the transfer failed).
#   Check that an ssh-key has already been installed to the remote machine and that ssh login is working. Consider making your script automate the ssh-keygen call if needed (maybe that should be a separate "install" script. Any automation of ssh-keygen should check that the specified remote user has superuser privileges.


# Data files that will be passed between the two computers.
file_user_data="temp_passwd_data.txt"
file_pass_data="temp_shadow_data.txt"
remove_data_files_after_use=false

# Check for correct number of command-line parameters.
if [ $# -ne 2 ]; then
    echo "Usage: $0 <user list file> <destination>"
    echo
    echo "Explanation"
    echo "  A newline-separated list of users is required along with a destination."
    echo
    echo "Example:"
    echo "  $0 bunch_of_users.txt root@192.168.1.257"
    echo
    exit 1
fi

# Check for superuser privileges.
if (( $EUID != 0 )); then
    echo "ERROR: This script must be called with sudo."
    exit 1
fi

# Check for pre-authorized ssh access to remote machine.

# Check that at least one user name from the given list was found among the users of this machine, if not then spit out an error to stderr. Then halt the script but give exit status of 0 since not matching any users should be a normal outcome.


# With all checks completed, proceed to actually doing stuff...

echo "Extracting local user data."
./extractPasswdData.sh < $1 > $file_user_data
./extractShadowData.sh < $1 > $file_pass_data

echo "Copying user data to home folder of $2"
scp $file_user_data $2:~
scp $file_pass_data $2:~

# Import the user data into the destination machine.
# NOTE: User importing is implemented with a loop because the newusers command has a 3-year old bug that is yet to be fixed. Under hard-to-control circumstances the program will crash with an "invalid next size" error message. The useradd command was selected because adduser is interaction-oriented.
ssh $2 << HERE
# Indices of data members in an /etc/passwd entry.
index_user=0
index_password=1
index_uid=2
index_gid=3
index_gecos=4
index_dir=5
index_shell=6

if [ $# -ne 1 ]; then
        echo "A script for importing a list of users from a field in the same format as an /etc/passwd file."
        echo "Usage: $0 <text file with user entries>"
fi

# Read in the new users and create their accounts.
while read line; do
    # Split the user's entry by colons into an array.
    IFS=':' read -r -a array_of_field_data <<< "$line"

    # Convert the array to a set of fields.
    field_user=${array_of_field_data[index_user]}
    field_password=${array_of_field_data[index_password]}
    field_uid=${array_of_field_data[index_uid]}
    field_gid=${array_of_field_data[index_gid]}
    field_gecos=${array_of_field_data[index_gecos]}
    field_dir=${array_of_field_data[index_dir]}
    field_shell=${array_of_field_data[index_shell]}

    # Create the new user (do not create a home directory).
    useradd -u $field_uid -g $field_gid -c "$field_gecos" -M -s $field_shell $field_user
done <$1

# Assign passwords to the new users.
chpasswd -e < shadow_output.txt
HERE

# Delete the temporary data files.
if $remove_data_files_after_use; then
    echo "Removing temporary files from local machine"
    rm $file_user_data
    rm $file_pass_data
    # Delete the remote copies.
fi


