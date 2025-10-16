import sys
import dbm

# Existing list of users, assuming the file is in the same directory as this script
USERS_LIST_FILE = "test_users_new_pass.txt"
CACHE_FILE = "user_cache"

def get_password(username):
    # Returns the password of a user if the username parameter matches with an existing user
    try:
        with open(USERS_LIST_FILE, 'r') as file:
            for line in file:
                user = line.strip()
                if user:
                    name, password = user.split(":")
                    if username == name:
                        return password.strip()
    except (IOError, OSError) as e:
        sys.exit(1)
    return None

def get_cached_password(username):
    # Returns the password of a cached user if the user exists in the cache
    try:
        with dbm.open(CACHE_FILE, 'r') as cache:
            if bytes(username, 'utf-8') in cache.keys():
                cache_pass_str = cache[username].decode('utf-8')
                return cache_pass_str.strip()
    except (IOError, OSError) as e:
        sys.exit(1)
    return None

def update_cached_password(username, new_password):
    # Updates the dbm cache for a single user with a new password, and outputs the updated password
    try:
        with dbm.open(CACHE_FILE, 'w') as cache:
            cache[username] = new_password
            print(new_password)
    except (IOError, OSError) as e:
        sys.exit(1)

def main():
    # Process standard input from command line
    users_to_search = []
    for line in sys.stdin:
        user = line.strip()
        users_to_search.append(user)

    # Loop through users and update passwords as necessary
    for user_to_search in users_to_search:
        current_password = get_password(user_to_search)
        cached_password = get_cached_password(user_to_search)
        if current_password != cached_password and cached_password is not None:
            update_cached_password(user_to_search, current_password)

if __name__ == "__main__":
    main()