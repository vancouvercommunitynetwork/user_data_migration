#!/bin/bash

# TO DO:
#   Check that the destination is reachable.
#   Check that file copying succeeds before attempting newusers and chpasswd (maybe the files couldn't be created for permission reasons or maybe the transfer failed).
#   Figure out what to do about that bug in newusers that causes the "Error in `newusers': free(): invalid next size (fast)" error messages (this stupid bug was confirmed two years ago and still isn't fixed!).
#   Check that an ssh-key has already been installed to the remote machine and that ssh login is working. Consider making your script automate the ssh-keygen call if needed (maybe that should be a separate "install" script.


# Data files that will be passed between the two computers.
file_user_data="extracted_user_data.txt"
file_pass_data="extracted_passwords.txt"
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

# With all checks completed, proceed to actually DOING stuff.

echo "Extracting local user data."
./extractPasswdData.sh < $1 > $file_user_data
./extractShadowData.sh < $1 > $file_pass_data

echo "Copying user data to home folder of $2"
scp $file_user_data $2:~
scp $file_pass_data $2:~

# Import the user data into the destination machine.


# Delete the temporary data files.
if $remove_data_files_after_use; then
    echo "Removing temporary files from local machine"
    rm $file_user_data
    rm $file_pass_data
    # Delete the remote copies.
fi


