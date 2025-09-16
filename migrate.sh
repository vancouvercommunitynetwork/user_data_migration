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

# ========== INITIALIZATION FUNCTIONS ==========

print_usage_message() {
    cat << EOF
Usage: ${PROGRAM_NAME} [DESTINATION] [USER LIST FILE]

Description: This script migrates users from a local machine to a remote machine

Prereq 1: The users file must be a text file containing a list of newline-separated usernames
Prereq 2: The network destination must be pre-authorized for ssh access

Example: ${PROGRAM_NAME} root@192.168.172.154 list_of_users.txt
EOF
}

lock_program_execution() {
    # Arbitrarily open/create file using descriptor 200 - potential source of issues if descriptor taken
    exec 200>"${LOCK_FILE}"
    # Try acquire exclusive lock over file to ensure only 1 script instace running
    if ! flock -n 200; then
        echo "ERROR: An instance of ${PROGRAM_NAME} is already running."
        exit ${EXIT_MULTIPLE_INSTANCES}
    fi

    # Write PID to lock file for debugging
    echo $$ >&200
}

check_parameter_count() {
    if  [[ $# -ne 2 ]]; then 
        print_usage_message
        exit ${EXIT_BAD_PARAMETERS}
    fi
}

check_user_level() {
    if [[ $EUID -ne 0 ]]; then 
        echo "ERROR: ${PROGRAM_NAME} must be called with root privileges so it can read /etc/shadow."
        exit ${EXIT_INSUFFICIENT_USER_LEVEL}
    fi
}

check_file_empty() {
    local user_list_file="$1"

    if [[ ! -r "$user_list_file" ]]; then
        echo "Error: Cannot read user list file" >&2
        exit ${EXIT_BAD_PARAMETERS}
    fi

    if [[ ! -s "$user_list_file" ]]; then
        echo "Error: User list file is empty" >&2
        exit ${EXIT_BAD_PARAMETERS}
    fi
}

# ========== USER DATA FUNCTIONS ==========

find_user_in_file() {
    local username="$1"
    local filepath="$2"

    if [[ -r "$filepath" ]]; then
        grep "^${username}:" "$filepath" 2>/dev/null
    fi
}

get_user_data() {
    local username="$1"
    local passwd_entry shadow_entry

    passwd_entry=$(find_user_in_file "$username" "$PASSWD_FILE")
    shadow_entry=$(find_user_in_file "$username" "$SHADOW_FILE")

    if [[ -z "$passwd_entry" || -z "$shadow_entry" ]]; then
        return 1
    fi

    # Parse passwd entry - username:password:userID:groupID:gecos:homeDir:shell
    IFS=":" read -ra passwd_fields <<< "$passwd_entry"

    # Parse shadow entry - username:password:lastchanged:minimum:maximum:warn:inactive:expire
    IFS=":" read -ra shadow_fields <<< "$shadow_entry"

    # Return a 1-liner string of user data: username:passwd_hash:group_id:gecos:shell
    echo "${passwd_fields[0]}:${shadow_fields[1]}:${passwd_fields[3]}:${passwd_fields[4]}:${NOLOGIN_SHELL}"
}

# Create list of usernames from input file - loads all usernames from input file into memory (potential issue)
read_user_list() {
    local user_list_file="$1"
    local usernames=()

    # Make sure the file is readable
    if [[ ! -r "$user_list_file" ]]; then
        echo "Error reading user list file: $user_list_file" >&2
        exit 1
    fi

    # loop over the file and add usernames to list
    while IFS= read -r username; do
        username=$(echo "$username" | tr -d '[:space:]')
        if [[ -n "$username" ]]; then 
            usernames+=("$username")
	fi
    done <  "$user_list_file"

    printf '%s\n' "${usernames[@]}"
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

