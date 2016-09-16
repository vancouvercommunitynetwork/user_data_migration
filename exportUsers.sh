#!/usr/bin/env bash

# TODO:
#   Check that the destination is reachable.
#   Check that file copying succeeds before attempting newusers and chpasswd (maybe the files couldn't be created for permission reasons or maybe the transfer failed).
#   Test the code for deleting the local temp files.
#   Write and test the code for deleting the remote temp files and the remote copy of importUsers.sh.
#   Rewrite Readme.md to properly describe the purpose and usage of all these scripts and their input and output files.
#   Check that an ssh-key has already been installed to the remote machine and that ssh login is working.
#       Something like this is apparently the way to go:
#           ssh -o BatchMode=yes -o ConnectTimeout=3 root@192.168.20.45 exit
#           This will yield an exit code of 255 if connecting failed or 0 if it worked.
#       Consider making your script automate the ssh-keygen call if needed (maybe that should be a separate "install" script. Any automation of ssh-keygen should check that the specified remote user has superuser privileges.
#   Check that at least one user name from the given list was found among the users of this machine, if not then spit out an error to stderr. Then halt the script but give exit status of 0 since not matching any users may be a common occurrence.
#   Add a remove_remote_temp_files_after_use flag and set it up to delete the temp files and remote copy of importUsers.sh.
#   Change your lock to generate the first available file descriptor rather than using the magic number of the constant 200.
#   Setup the helper scripts to use the same lock as exportUsers.sh.

 
############################################################
#              DECLARATIONS AND DEFINITIONS                #
############################################################

set -e  # Exit script on command failures.
set -u  # Exit script on attempted use of undeclared variables.

# Files that will be passed to the remote machine.
file_user_data="temp_passwd_data.txt"
file_pass_data="temp_shadow_data.txt"
script_remote_migration="importUsers.sh"

# Settings.
remove_local_temp_files_after_use=true
remove_import_script_after_use=false
filename_to_lock="/var/run/vcn_user_data_migration.lck"

# Exit failure status values.
readonly EXIT_MULTIPLE_INSTANCE=1
readonly EXIT_BAD_PARAMETERS=2
readonly EXIT_INSUFFICIENT_USER_LEVEL=3
readonly EXIT_IMPORT_SCRIPT_NOT_FOUND=4

# Attempt an exclusive lock of execution of this script. Exit in the event of failure.
exclusiveLock() {
    exec 200>$filename_to_lock
    flock -n 200 || {
        echo "ERROR: A previous instance of $(basename $0) is already running."
        exit $EXIT_MULTIPLE_INSTANCE
    }
    echo $$ 1>&200
}

# Check for correct number of command-line parameters.
checkParameterCount(){
    local parameterCount=$1
    if [ $parameterCount -ne 2 ]; then cat <<HERE
Usage: $0 [USER LIST FILE] [DESTINATION]
Emigrate given users from this machine to a remote machine. The user list must be a text file containing a newline-separated list of usernames. The network destination needs to be pre-authorized for ssh access which can be done with ssh-keygen.

Example:
  $0 bunch_of_users.txt root@192.168.1.257

HERE
        exit $EXIT_BAD_PARAMETERS
    fi
}

# Check for superuser privileges.
checkUserLevel(){
    if (( $EUID != 0 )); then
        echo "ERROR: $(basename $0) must be called as sudo so it can read /etc/shadow."
        exit $EXIT_INSUFFICIENT_USER_LEVEL
    fi
}

# Check that a local copy of the importation script is present.
checkImportScriptIsPresent(){
    if [ ! -f "$script_remote_migration" ]; then
        echo "Could not find local copy of remote migration script: $script_remote_migration"
        exit $EXIT_IMPORT_SCRIPT_NOT_FOUND
    fi
}


############################################################
#                MAIN BODY OF PROGRAM                      #
############################################################

# Prevent more than one instance of this script from executing simultaneously.
exclusiveLock

# Check that migration prerequisites are met.
checkParameterCount $#          # The parameter count should be correct.
checkUserLevel                  # This script must be called as root.
checkImportScriptIsPresent      # A local copy of importUsers.sh must be present.

# Name program parameters.
user_list=$1
destination=$2

# Proceed with migration.
echo "Extracting local user data to: $file_user_data"
./extractPasswdData.sh < $user_list > $file_user_data

echo "Extracting local user passwords to: $file_pass_data"
./extractShadowData.sh < $user_list > $file_pass_data

echo "Copying user data to home folder of $destination"
scp $file_user_data $destination:~
scp $file_pass_data $destination:~

echo "Copying remote migration script to home folder of $destination"
scp $script_remote_migration $destination:~

echo "Attempting to execute remote migration script on destination machine..."
ssh -t $destination "./$script_remote_migration $file_user_data $file_pass_data"
echo "Remote migration attempt complete."

# Delete the temporary data files.
if "$remove_local_temp_files_after_use"; then
    echo "Removing temporary files from local machine."
    rm $file_user_data
    rm $file_pass_data
fi

