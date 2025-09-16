#!/usr/bin/env bash

# TODO:
#   Check that the destination is reachable.
#   Check that an ssh-key has already been installed to the remote machine and that ssh login is working.
#       Something like this is apparently the way to go:
#           ssh -o BatchMode=yes -o ConnectTimeout=3 root@192.168.20.45 exit
#           This will yield an exit code of 255 if connecting failed or 0 if it worked.
#   Check that at least one user name from the given list was found among the users of this machine, if not then spit out an error to stderr. Then halt the script but give exit status of 0 since not matching any users may be a common occurrence.
#   Change your lock to generate the first available file descriptor rather than using the magic number of the constant 200.

############################################################
#              DECLARATIONS AND DEFINITIONS                #
############################################################

# Settings
LOCK_FILE="/var/run/vcn_user_migrate.lck"
CACHE_FILE="/var/run/vcn_user_cache.txt"
NOLOGIN_SHELL="/usr/sbin/nologin"
PROGRAM_NAME=$(basename "$0")

# Exit codes
EXIT_MULTIPLE_INSTANCES=1
EXIT_BAD_PARAMETERS=2
EXIT_INSUFFICIENT_USER_LEVEL=3

# File paths
PASSWD_FILE="/etc/passwd"
SHADOW_FILE="/etc/shadow"

# Arrays used for migration tracking
declare -a USERS_TO_MIGRATE
declare -a USERS_TO_DELETE
declare -A CURRENT_CACHE

# Print a description of how the program should be called.
printUsageMessage(){
cat <<HERE
Usage: $0 [DESTINATION] [USER LIST FILE]
Migrate users from this machine to a remote machine. The user list must be a text file containing a newline-separated list of usernames. The network destination needs to be pre-authorized for ssh access which can be done with ssh-keygen.

Example:
  $0 root@192.168.1.257 bunch_of_users.txt

HERE
}

# Attempt an exclusive lock of execution of this script. Exit in the event of failure.
lockProgramExecution() {
    exec 200>$lock_file
    flock -n 200 || {
        echo "ERROR: A previous instance of $(basename $0) is already running."
        exit $EXIT_MULTIPLE_INSTANCE
    }
    echo $$ 1>&200
}

# Check for correct number of command-line parameters.
checkParameterCount(){
    local parameterCount=$1
    if [ $parameterCount -ne 2 ]; then
        printUsageMessage
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


############################################################
#                MAIN BODY OF PROGRAM                      #
############################################################

# Run various initialization checks.
checkUserLevel           # User must have sudo privilege.
checkParameterCount $#   # Check program was given correct arguments.
lockProgramExecution     # Don't allow more than one instance to run.

# For each user...
while read user_name; do
    # Try to get user's data from /etc/passwd and /etc/shadow.
    passwd_result=$(grep "^$user_name:" /etc/passwd)
    shadow_result=$(grep "^$user_name:" /etc/shadow)

    # If user's data was found...
    if [ ! -z "$passwd_result" ] && [ ! -z "$shadow_result" ]; then
        # Split entry components into arrays of fields.
        IFS=':' read -r -a passwd_fields <<< "$passwd_result"
        IFS=':' read -r -a shadow_fields <<< "$shadow_result"

        # Pull the needed fields from the arrays. The field ordering in passwd and shadow are:
        #    username:password:userID:groupID:gecos:homeDir:shell
        #    username:password:lastchanged:minimum:maximum:warn:inactive:expire
        name=${passwd_fields[0]}     # Username.
        pass=${shadow_fields[1]}     # User's encrypted password.
        gid=${passwd_fields[3]}      # User's group ID.
        gecos=${passwd_fields[4]}    # User's info (full name).
        shell="/usr/sbin/nologin"   # Shell disabled for security.        

        # Remotely add user accounts (ssh will halt loop without -n).
        echo Migrating user: $name
        # Update remote user account by deleting and recreating it. Note that deluser output is nullified to prevent it from clogging this program's output with irrelevant messages.
        ssh -n $1 deluser $name '> /dev/null 2> /dev/null'
        ssh -n $1 /usr/sbin/useradd -p \'$pass\' -g $gid -c \"$gecos\" -M -s $shell $name
    fi
done <"$2"

