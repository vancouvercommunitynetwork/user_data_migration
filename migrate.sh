#!/bin/bash

echo "Script started" 
echo 

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


# ========== CACHE MANAGEMENT FUNCTIONS ==========

# Extract all user data from previous run's cache
load_cache() {
    declare -A cache

    # Extract line from file and store in cache
    if [[ -r "$CACHE_FILE" ]]; then
	while IFS= read -r line; do
	    if [[ -n "$line" ]]; then
		local username="${line%%:*}"
		cache["$username"]="$line"
	    fi
	done < "$CACHE_FILE"
    fi

    # Output all cache entries as key-value pairs
    for username in "${!cache[@]}"; do
	echo "${username}=${cache[$username]}"
    done
}

# Saves newly built cache to cache location
save_cache() {
    local content=""

    # Build content from current_cache associative array
    for username in "${!current_cache[@]}"; do
	content+="${current_cache[$username]}"$'\n'
    done

    # Save current user data to cache file for next run
    if ! echo "$content" > "$CACHE_FILE"; then
        echo "Warning: Could not save cache file" >&2
    fi
}

# Update backup cache with previous run's cache
backup_previous_cache() {
    if [[ -f "$CACHE_FILE" ]]; then
	local backup_file="${CACHE_FILE}.backup"
        if mv "$CACHE_FILE" "$backup_file"; then
            echo "Previous cache backed up to: $backup_file"
        else
	    echo "Warning: Could not backup cache file" >&2
        fi
    fi
}


# ========== MIGRATION LOGIC ==========

user_needs_migration() {
    local username="$1"
    local current_user_data="$2"
    local previous_cache_entry="$3"

    # Check for users deleted previously but still in input list
    if [[ -z "$current_user_data" ]]; then
    	if [[ -z "$previous_cache_entry" ]]; then
            echo " $username: User not found locally or in backup cache, skipping"
            return
    	fi
    fi

    # Check for recently deleted users - user absent from passwd/shadow file but found in previous run cache
    if [[ -z "$current_user_data" ]]; then
	if [[ -n "$previous_cache_entry" ]]; then
	    echo " $username: User deleted locally, will be deleted from server"
	    USERS_TO_DELETE+=("$username")
	fi
        return
    fi

    # Check for created users - user present in passwd/shadow file but not found in previous run cache
    if [[ -z "$previous_cache_entry" ]]; then
	if [[ -n "$current_user_data" ]]; then
	    echo " $username: New user"
	    USERS_TO_MIGRATE+=("$current_user_data")
	else
	    echo " $username not found locally or in previous cache, skipping"
	fi
        return
    fi

    # Check for changes in existing users
    if [[ "$current_user_data" != "$previous_cache_entry" ]]; then
	echo " $username: User data changed"
	USERS_TO_MIGRATE+=("$current_user_data")
	return
    fi

    # No changes detected
    echo " $username: No changes, skipping"
}

# ========== REMOTE OPERATIONS ==========

bulk_migrate_users() {
    local destination="$1"

    if [[ ${#USERS_TO_MIGRATE[@]} -eq 0 && ${#USERS_TO_DELETE[@]} -eq 0 ]]; then
	echo "No operations to perform"
	return
    fi

    echo "Creating migration script..."
    local script_content
    script_content=$(create_migration_script)

    echo "Executing remote operations..."
    execute_migration_script "$destination" "$script_content"
}

# Performs the actual execution of the migration script
execute_migration_script() {
    local destination="$1"
    local script_content="$2"

    # Send script via stdin to remote bash and execute it
    if echo "$script_content" | ssh "$destination" 'bash'; then
	echo "Remote script executed successfully"
    else
	echo "Remote script failed"
    fi
} 

# Creates script containing all delete and create operations to update remote server
create_migration_script() {
    local script_lines="#!/bin/bash\n\n"

    # Add delete operations
    if [[ ${#USERS_TO_DELETE[@]} -gt 0 ]]; then
	for username in "${USERS_TO_DELETE[@]}"; do
	    script_lines+="$(delete_remote_user "$username")\n"
	done
    	script_lines+="\n"
    fi

    # Add migrate operations
    if [[ ${#USERS_TO_MIGRATE[@]} -gt 0 ]]; then
	for user_data in "${USERS_TO_MIGRATE[@]}"; do
	    IFS=":" read -ra user_fields <<< "$user_data" # Split data into array to extract username
	    local username="${user_fields[0]}"
	    script_lines+="$(delete_remote_user "$username")\n"
	    script_lines+="$(create_remote_user "$user_data")\n"
	done
    fi

    echo -e "$script_lines"
}

# Generates delete user command
delete_remote_user() {
    local username="$1"
    echo "deluser $username > /dev/null 2> /dev/null"
}

# Generates create user command
create_remote_user() {
    local user_data="$1"
    IFS=":" read -ra user_fields <<< "$user_data"

    local username="${user_fields[0]}"
    local password_hash="${user_fields[1]}"
    local group_id="${user_fields[2]}"
    local gecos="${user_fields[3]}"
    local shell="${user_fields[4]}"

    # Replace dollar signs in password hash by replacing them with \\$
    password_hash="${password_hash//$/\\$}"

    # Produce full command (force group ID to 100)
    echo "/usr/sbin/useradd -p '$password_hash' -g 100 -c \"$gecos\" -M -s $shell $username > /dev/null 2> /dev/null" 
}


# ========== MAIN PROGRAM BODY ==========
main() {
    # Perform checks
    check_user_level
    check_parameter_count "$@"
    lock_program_execution

    # Get cmd line args
    local destination="$1"
    local user_list_file="$2"

    # Load previous cache in memory and back it up
    echo "Loading previous cache"
    declare -A previous_cache
    while IFS='=' read -r username cache_entry; do
	previous_cache["$username"]="$cache_entry"
    done < <(load_cache)
    backup_previous_cache

    # Read the list of users into an array
    echo "Reading user list..."
    readarray -t usernames < <(read_user_list "$user_list_file")

    # Initialize arrays
    USERS_TO_MIGRATE=()
    USERS_TO_DELETE=()
    declare -A input_users_set  # Used to check for users deleted from input list
    declare -A current_cache    # Updated representation of shadow and passwd files

    # Iterate over usernames input file 
    for username in "${usernames[@]}"; do
	local current_user_data
	current_user_data=$(get_user_data "$username")

	# Add username to input_users_set for later checking
	input_users_set["$username"]=1

	# Add the user data to the current cache
	if [[ -n "$current_user_data" ]]; then
	    current_cache["$username"]="$current_user_data"
	fi

	# determine if user needs migration
	user_needs_migration "$username" "$current_user_data" "${previous_cache[$username]}"
    done

    # Look for users removed from input list but remain in cache
    for cached_username in "${!previous_cache[@]}"; do
	if [[ -z "${input_users_set[$cached_username]}" ]]; then
	    echo " $cached_username: User no longer in input list, will remove from remote machine"
	    USERS_TO_DELETE+=("$cached_username")
	fi
    done

    # Perform all remote operations in a single SSH connection
    if [[ ${#USERS_TO_DELETE[@]} -gt 0 || ${#USERS_TO_MIGRATE[@]} -gt 0 ]]; then
	bulk_migrate_users "$destination"
    else
	echo "No users need migration or deletion"
    fi

    # Save current cache for next run
    echo "Saving cache for next run"
    save_cache
    echo "Migration complete"
}

main "$@"
