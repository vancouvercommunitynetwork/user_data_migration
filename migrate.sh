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
