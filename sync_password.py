import sys
import dbm
import subprocess

# Existing list of users, assuming the file is in the same directory as this script
USERS_LIST_FILE = "test_users_new_pass.txt"
CACHE_FILE = "user_cache"

def get_password(user_list_file, username):
    # Returns the password of a user if the username parameter matches with an existing user
    try:
        with open(user_list_file, 'r') as file:
            for line in file:
                user = line.strip()
                if user:
                    name, password = user.split(":")
                    if username == name:
                        return password.strip()
    except (IOError, OSError) as e:
        sys.exit(1)
    return None

def get_cached_password(cache_file, username):
    # Returns the password of a cached user if the user exists in the cache
    try:
        with dbm.open(cache_file, 'r') as cache:
            if bytes(username, 'utf-8') in cache.keys():
                cache_pass_str = cache[username].decode('utf-8')
                return cache_pass_str.strip()
    except (IOError, OSError) as e:
        sys.exit(1)
    return None

def update_cached_password(cache_file, username, new_password):
    # Updates the dbm cache for a single user with a new password, and outputs the updated password
    try:
        with dbm.open(cache_file, 'w') as cache:
            cache[username] = new_password
    except (IOError, OSError) as e:
        sys.exit(1)

def sync_password(username, password = ""):
    # Run the linux command for password sync
    if (password == ""):
        return False
    
    command = f"""ssh -n user@remote_host "sudo userdel -r {username} && sudo useradd -p '{password}' -M -s /usr/sbin/nologin {username}" {username}"""
    try:
        subprocess.run(command, shell=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        return False

def main():
    # Process standard input from command line
    users_to_search = []
    for line in sys.stdin:
        user = line.strip()
        users_to_search.append(user)

    # Loop through users and update passwords as necessary
    for username in users_to_search:
        current_password = get_password(USERS_LIST_FILE, username)
        cached_password = get_cached_password(CACHE_FILE, username)
        if current_password != cached_password and cached_password is not None:
            if sync_password(username, current_password):
                update_cached_password(CACHE_FILE, username, current_password)
            
if __name__ == "__main__":
    main()