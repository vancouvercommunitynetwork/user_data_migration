#!/bin/bash

# TO DO:
#   Check that the destination is reachable.
#   Check that file copying succeeds before attempting newusers and chpasswd (maybe the files couldn't be created for permission reasons or maybe the transfer failed).
#   Figure out what to do about that bug in newusers that causes the "Error in `newusers': free(): invalid next size (fast)" error messages (this stupid bug was confirmed two years ago and still isn't fixed!).


# Temporary data files that will be passed between the two computers.
file_user_data="extracted_user_data.txt"
file_pass_data="extracted_passwords.txt"
delete_temporary_data_files=true

# Check for correct number of command-line parameters.
if [ $# -ne 2 ]; then
    echo "Usage: $0 <user list file> <destination>"
    echo
    echo "Explanation"
    echo "  A newline-separated list of users is required along with a destination."
    echo
    echo "Example:"
    echo "  $0 bunch_of_users.txt root@192.168.1.257:/home"
    echo
    exit 1
fi

# Extract the user data.
./extractPasswdData.sh < $1 > $file_user_data
./extractShadowData.sh < $1 > $file_pass_data

# Copy the user data to the destination machine.
scp $file_user_data $2
scp $file_pass_data $2

# Import the user data into the destination machine.

# Delete the temporary data files.
if $delete_temporary_data_files; then
    rm $file_user_data
    rm $file_pass_data
fi


