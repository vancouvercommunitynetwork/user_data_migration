#!/bin/bash

# TO DO:
#   Check that the destination is reachable.
#   Check that file copying succeeds before attempting newusers and chpasswd (maybe the files couldn't be created for permission reasons or maybe the transfer failed).
#   Check that an ssh-key has already been installed to the remote machine and that ssh login is working. Consider making your script automate the ssh-keygen call if needed (maybe that should be a separate "install" script. Any automation of ssh-keygen should check that the specified remote user has superuser privileges.
#   Test the code for deleting the local temp files.
#   Write and test the code for deleting the remote temp files and the remote copy of importUsers.sh.


# Files that will be passed to the remote machine.
file_user_data="temp_passwd_data.txt"
file_pass_data="temp_shadow_data.txt"
script_remote_migration="importUsers.sh"
remove_data_files_after_use=false
remove_import_script_after_use=false

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
    echo "ERROR: $0 must be called as sudo so it can read /etc/shadow."
    exit 1
fi

# Check that a local copy of the importation script is present.
if [! -f $script_remote_migration]; then
    echo "Could not find local copy of remote migration script: $script_remote_migration"
    exit 1
fi

# Check for pre-authorized ssh access to remote machine.

# Check that at least one user name from the given list was found among the users of this machine, if not then spit out an error to stderr. Then halt the script but give exit status of 0 since not matching any users may be a common occurrence.


# With all checks completed, proceed to actually doing stuff...
echo "Extracting local user data."
./extractPasswdData.sh < $1 > $file_user_data
./extractShadowData.sh < $1 > $file_pass_data

echo "Copying user data to home folder of $2"
scp $file_user_data $2:~
scp $file_pass_data $2:~

echo "Copying remote migration script to home folder of $2"
scp $script_remote_migration $2:~

echo "Attempting to execute remote migration script on destination machine..."
ssh -t $2 "./$script_remote_migration $file_user_data $file_pass_data"
echo "Remote migration attempt complete."

# Delete the temporary data files.
if $remove_data_files_after_use; then
    echo "Removing temporary files from local machine"
    rm $file_user_data
    rm $file_pass_data
    # Delete the remote copies.
fi

# Delete the import script that was temporarily copied to the remote machine.

