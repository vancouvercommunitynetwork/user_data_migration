#!/bin/bash

# TO DO:
#   Check that the destination is reachable.
#   Check that file copying succeeds before attempting newusers and chpasswd (maybe the files couldn't be created for permission reasons or maybe the transfer failed).
#   Check that an ssh-key has already been installed to the remote machine and that ssh login is working. Consider making your script automate the ssh-keygen call if needed (maybe that should be a separate "install" script.


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
# NOTES:
#   The newusers command has a 3-year old bug that is yet to be fixed. Under hard-to-control circumstances the program will crash with an "invalid next size" error message.
#   The adduser command is a poor fit because it's interactive and creates a home-directory for new users which we don't need. Hence the decision to go with the low-level useradd command.

# Delete the temporary data files.
if $remove_data_files_after_use; then
    echo "Removing temporary files from local machine"
    rm $file_user_data
    rm $file_pass_data
    # Delete the remote copies.
fi


