
# To do next time:
# 1. create 3 full users locally and run the script with them
# the last thing I did was run the following operations to see if they would work:
# ssh root@192.168.172.140 "deluser testuser2 > /dev/null 2> /dev/null"
# ssh root@192.168.172.140 "/usr/sbin/useradd -p '!' -g 1003 -c \"\" -M -s /usr/sbin/nologin testuser2"
# Deleting user worked but not creating them because of missing password, so we need complete users

import sys
import os
import subprocess
import fcntl
import json

print("Script started \n")

# Settings
LOCK_FILE = "/var/run/vcn_user_data_migration.lck"
CACHE_FILE = "/var/run/vnc_user_migration_cache.json"
NOLOGIN_SHELL = "/usr/sbin/nologin"
PROGRAM_NAME = os.path.basename(sys.argv[0])

# Exit codes
EXIT_MULTIPLE_INSTANCE = 1
EXIT_BAD_PARAMETERS = 2
EXIT_INSUFFICIENT_USER_LEVEL = 3

# File paths
PASSWD_FILE = "/etc/passwd"
SHADOW_FILE = "/etc/shadow"


# ========== Initialization Functions ==========

# Prints a description of how the program should be called
def print_usage_message():
    usage_text = f"""Usage: {PROGRAM_NAME} [DESTINATION] [USER LIST FILE]
    \n\nDescription: This script migrates users from local machine to remote machine. 
    \nPrereq 1: The users file must be a text file containing a list of newline-separated usernames. 
    \nPrereq 2: The network destination must be pre-authorized for ssh access, which can be done with ssh-keygen.
    
    \nExample: {PROGRAM_NAME} root@192.168.1.257 list_of_users.txt
    """
    print(usage_text)

# Creates/obtains exclusive lock on script
def lock_program_execution():
    try:
       # Open/create lock file and lock
       lock_fd = os.open(LOCK_FILE, os.O_WRONLY | os.O_CREAT)  # Open/create file for reading and get descriptor
       fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)     # Put lock on file/fail immediately if file is taken

       # Write PID to lock file
       pid_bytes = str(os.getpid()).encode()
       os.write(lock_fd, pid_bytes)

       return lock_fd
    except (OSError, IOError):
        print(f"ERROR: An instance of {PROGRAM_NAME} is already running.")
        sys.exit(EXIT_MULTIPLE_INSTANCE)

# Checks correct number of command line parameters provided
def check_parameter_count():
    if len(sys.argv) != 3:
        print_usage_message()
        sys.exit(EXIT_BAD_PARAMETERS)

# Checks user has superuser privileges
def check_user_level():
    if os.getuid() != 0:
        print(f"ERROR {PROGRAM_NAME} must be called as sudo so it can read /etc/shadow.")
        sys.exit(EXIT_INSUFFICIENT_USER_LEVEL)


# ========== User Data Functions ==========

# Finds a user in a system file
def find_user_in_file(username, filepath):
    try:
        with open(filepath, 'r') as file:
            for line in file:
                if line.startswith(f"{username}:"):
                    return line.strip()
    except (IOError, OSError) as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)
        return None

# Extracts user data from /etc/passwd and /etc/shadow files
def get_user_data(username):
    passwd_entry = find_user_in_file(username, PASSWD_FILE)
    shadow_entry = find_user_in_file(username, SHADOW_FILE)

    if not passwd_entry or not shadow_entry:
        return None

    # Parse passwd entry - username:password:userID:groupID:gecos:homeDir:shell
    passwd_fields = passwd_entry.split(':')

    #Parse shadow entry - username:password:lastchanged:minimum:maximum:warn:inactive:expire
    shadow_fields = shadow_entry.split(':')

    # Create dictionary of user data
    user_data = {
        'name': passwd_fields[0],
        'password_hash': shadow_fields[1],
        'group_id': passwd_fields[3],
        'gecos': passwd_fields[4],
        'shell': NOLOGIN_SHELL
    }

    return user_data

# Create list of usernames from input file
def read_user_list(user_list_file):
    try :
        with open(user_list_file, 'r') as file:
            usernames = []
            for line in file:
                username = line.strip()
                if username:
                    usernames.append(username)
            return usernames
    except(IOError, OSError) as e:
        print(f"Error reading user list file: {e}", file=sys.stderr)
        sys.exit(1)


# ========== Cache Management Functions ==========

# Loads the previous run's cache file
def load_cache():
    try:
        with open(CACHE_FILE, 'r') as file:
            return json.load(file)
    except (IOError, OSError, json.JSONDecodeError):
        return {}

# Save current user data to cache file for next run
def save_cache(cache_data):
    try:
        with open(CACHE_FILE, 'w') as file:
            json.dump(cache_data, file, indent=2)
    except(IOError, OSError) as e:
        print(f"Warning: Could not save cache file: {e}", file=sys.stderr)

# Move current cache to backup before creating a new one
def backup_previous_cache():
    if os.path.exists(CACHE_FILE):
        backup_file = f"{CACHE_FILE}.backup"
        try:
            os.rename(CACHE_FILE, backup_file)
            print(f"Previous cache backed up to: {backup_file}")
        except (IOError, OSError) as e:
            print(f"Warning: Could not backup cache file: {e}", file=sys.stderr)


# ========== Migration Logic ==========

# Compare current user data with previous cache to determine if migration is needed
# Build 2 lists, users_to_delete and users_to_migrate
def user_needs_migration(username, current_user_data, previous_cache, users_to_migrate, users_to_delete):
    print(f"Checking user {username}")
    print(f"current_user_data = {current_user_data}")
    print(f"username in previous_cache = {username in previous_cache}")

    # Check for deleted users
    if not current_user_data:
        if username in previous_cache:
            print(f" {username}: User deleted locally, will be deleted from server")
            users_to_delete.append(username)
        return

    # Check for created users
    if username not in previous_cache:
        # Make sure user actually exists locally
        if current_user_data:
            print(f" {username}: New user")
            users_to_migrate.append(current_user_data)
        else:
            print(f" {username} not foud locally or backup cache, skipping")
        return

    # Having checked for created/deleted users, we now check for data changes in users

    previous_user_data = previous_cache[username]

    # Check if password was changed
    if current_user_data['password_hash'] != previous_user_data.get('password_hash'):
        print(f" {username}: Password changed")
        users_to_migrate.append(current_user_data)
        return

    # Check if group ID was changed
    if current_user_data['group_id'] != previous_user_data.get('group_id'):
        print(f" {username}: Group ID changed")
        users_to_migrate.append(current_user_data)
        return

    # Check if gecos were changed
    if current_user_data['gecos'] != previous_user_data.get('gecos'):
        print(f" {username}: User info changed")
        users_to_migrate.append(current_user_data)
        return

    # No changes detected
    print(f" {username}: No changes, skipping")
    return


# ========== Remote Operations =========

def bulk_migrate_users(destination, users_to_migrate, users_to_delete):
    # Perform all user operations in a single ssh connection
    if not users_to_migrate and not users_to_delete:
        print("No operations to perform")
        return

    print("Creating migration script...")
    script_content = create_migration_script(users_to_migrate, users_to_delete)

    print("Executing remote operations...")
    execute_migration_script(destination, script_content)

# Send script via stdin to remote bash and execute it
def execute_migration_script(destination, script_content):
    try:
        process = subprocess.run(['ssh', destination, 'bash'],
                                 input=script_content, text=True,
                                 capture_output=True)

        if process.returncode == 0:
            if process.stdout.strip():
                print("Remote script executed successfully")
                print(f"Script output: {process.stdout.strip()}")
            else:
                print(f"Remote script failed with return code: {process.returncode}")
                if process.stdout.strip():
                    print(f"Script errors: {process.stderr.strip()}")
    except subprocess.SubprocessError as e:
        print(f"Failed to execute remote script: {e}")


# Creates a bash script with all user operations and returns it as a string
def create_migration_script(users_to_migrate, users_to_delete):
    script_lines = ["#!/bin/bash", ""]

    # Add delete operations
    if users_to_delete:
        for username in users_to_delete:
            script_lines.append(delete_remote_user(username))
        script_lines.append("")

    # Add migrate operations
    if users_to_migrate:
        for user_data in users_to_migrate:
            script_lines.append(delete_remote_user(user_data['name']))
            script_lines.append(create_remote_user(user_data))

    return "\n".join(script_lines)

# Delete a user on the remote machine
def delete_remote_user(username):
    # Generate command to delete user
    return f"deluser {username} > /dev/null 2> /dev/null"

# Create a user on the remote machine
def create_remote_user(user_data):
    # Generate command to create user
    password = user_data['password_hash'].replace('$', '\\$') # Stops bash from treating $ as special characted in password
    return (f"/usr/sbin/useradd "
            f"-p '{password}' "
            f"-g 100 " # Forcing group 100. 100 should be replaced by {user_data['group_id']} to copy real users group
            f"-c \"{user_data['gecos']}\" "
            f"-M "
            f"-s {user_data['shell']} "
            f"{user_data['name']} > /dev/null 2> /dev/null")

# ========== Main Program Body ==========

def main():
    check_user_level()                  # User must have sudo privileges
    check_parameter_count()             # Program must be given the correct num of parameters
    lock_fd = lock_program_execution()  # Don't allow multiple instances

    # Get command line arguments
    destination = sys.argv[1]
    user_list_file = sys.argv[2]

    try:
        # Load previous cache and back it up
        print("Loading previous cache...")
        previous_cache = load_cache()
        backup_previous_cache()

        usernames = read_user_list(user_list_file)
        print(f"Checking {len(usernames)} users for changes...")

        # Read the list of users to check
        z
        users_to_migrate = []
        users_to_delete = []

        # Check each user in the input list
        for username in usernames:
            current_user_data = get_user_data(username)

            if current_user_data:
                # Add user to new cache
                current_cache[username] = current_user_data

            # Determine whether user needs migration/deletion in remote server
            user_needs_migration(username, current_user_data, previous_cache, users_to_migrate, users_to_delete)

        # Check for users deleted from input usernames list but remain in cache
        for cached_username in previous_cache:
            if cached_username not in [u for u in usernames]:
                print(f" {cached_username}: User no longer in input list, will remove from remote")
                users_to_delete.append(cached_username)

        # Report summary
        print(f"\n\nSummary:")
        print(f"  Total users checked: {len(usernames)}")
        print(f"  Users needing migration: {len(users_to_migrate)}")
        print(f"  Users to delete from remote: {len(users_to_delete)}")
        print(f"  Users skipped (no changes): {len(usernames) - len(users_to_migrate)}")

        # Perform all remote operations in a single SSH connection

        if users_to_delete or users_to_migrate:
            bulk_migrate_users(destination, users_to_migrate, users_to_delete)
        else:
            print("\nNo users need migration or deletion")

        # Save current cache for next run
        print("Saving cache for next run")
        save_cache(current_cache)
        print("Migration complete!")

    finally:
        try:
            os.close(lock_fd)
        except:
            pass

if __name__ == "__main__":
    main()
