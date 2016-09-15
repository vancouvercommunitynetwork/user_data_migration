#!/usr/bin/env bash

# TODO:
#   Check that the destination is reachable.
#   Check that file copying succeeds before attempting newusers and chpasswd (maybe the files couldn't be created for permission reasons or maybe the transfer failed).
#   Check that an ssh-key has already been installed to the remote machine and that ssh login is working. Consider making your script automate the ssh-keygen call if needed (maybe that should be a separate "install" script. Any automation of ssh-keygen should check that the specified remote user has superuser privileges.
#   Test the code for deleting the local temp files.
#   Write and test the code for deleting the remote temp files and the remote copy of importUsers.sh.
#   Add constants for exit codes.
#   Rewrite Readme.md to properly describe the purpose and usage of all these scripts and their input and output files.
#   Setup locking:
#       You might need something like lock_file="/var/run/vcn_user_data_migration.lck"
#   Check for pre-authorized ssh access to remote machine.
#       Something like this is apparently the way to go:
#           ssh -o BatchMode=yes -o ConnectTimeout=3 root@192.168.20.45 exit
#       This will yield an exit code of 255 if connecting failed or 0 if it worked.
#   Check that at least one user name from the given list was found among the users of this machine, if not then spit out an error to stderr. Then halt the script but give exit status of 0 since not matching any users may be a common occurrence.
#   Lock each of the temporary files (separately).
#   Lock all the code after the declarations and definitions (using flock). Example code:
#       exec 200>$lock
#       flock -n 200 || exitBecauseOfLockFailure
#       echo $$ 1>&200
#   Unlock at the end of the script and unlock temporary files.


 
set -e  # Exit script on command failures.
set -u  # Exit script on attempted use of undeclared variables.

# Files that will be passed to the remote machine.
file_user_data="temp_passwd_data.txt"
file_pass_data="temp_shadow_data.txt"
script_remote_migration="importUsers.sh"

# Settings.
remove_data_files_after_use=true
remove_import_script_after_use=false
lock="/var/run/vcn_user_data_migration.lck"

# Exit failure status values.
EXIT_MULTIPLE_INSTANCE=1
EXIT_BAD_PARAMETERS=2
EXIT_INSUFFICIENT_USER_LEVEL=3
EXIT_IMPORT_SCRIPT_NOT_FOUND=4

exitBecauseOfLockFailure(){
    echo "Instance of $(basename "$0") already running!" 
    exit EXIT_MULTIPLE_INSTANCE
}

# Check for correct number of command-line parameters.
checkParameterCount(){
    if [ $1 -ne 2 ]; then
        echo "Usage: $0 <user list file> <destination>"
        echo
        echo "Explanation"
        echo "  This program requires a text file containing a newline-separated list of usernames and a network destination with pre-authorized ssh access."
        echo
        echo "Example:"
        echo "  $0 bunch_of_users.txt root@192.168.1.257"
        echo
        exit EXIT_BAD_PARAMETERS
    fi
}

# Check for superuser privileges.
checkUserLevel(){
    if (( $EUID != 0 )); then
        echo "ERROR: $(basename $0) must be called as sudo so it can read /etc/shadow."
        exit EXIT_INSUFFICIENT_USER_LEVEL
    fi
}

# Check that a local copy of the importation script is present.
checkImportScriptIsPresent(){
    if [ ! -f "$script_remote_migration" ]; then
        echo "Could not find local copy of remote migration script: $script_remote_migration"
        exit EXIT_IMPORT_SCRIPT_NOT_FOUND
    fi
}


# Test script execution prerequisites.
checkParameterCount $#          # Was this called with correct parameter count?
checkUserLevel                  # Was this called as sudo?
checkImportScriptIsPresent      # Is a local copy of importUsers.sh present?

# Proceed with migration.
echo "Extracting local user data to: $file_user_data"
./extractPasswdData.sh < $1 > $file_user_data

echo "Extracting local user passwords to: $file_pass_data"
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
if "$remove_data_files_after_use"; then
    echo "Removing temporary files from local machine."
    rm $file_user_data
    rm $file_pass_data
    # Delete the remote copies.
fi

