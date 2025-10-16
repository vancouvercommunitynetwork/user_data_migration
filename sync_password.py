import sys
import dbm

# Existing list of users, assuming the file is in the same directory as this script
USERS_LIST_FILE = "test_users_new_pass.txt"
CACHE_FILE = "user_cache"

def get_users_list(user_list_file):
    # Store usernames/passwords for reference in a dictionary
    users = {}

    try:
        with open(user_list_file, 'r') as file:
            for line in file:
                user = line.strip()
                if user:
                    username, password = user.split(":")
                    # Store username and password
                    users[username] = password 
            return users
    except (IOError, OSError) as e:
        print(f"Error reading user list file: {e}", file=sys.stderr)
        sys.exit()

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
        print(f"Error reading user list file: {e}", file=sys.stderr)
        sys.exit()
    return None

def get_cached_password(username):
    # Returns the password of a cached user if the user exists in the cache
    try:
        with dbm.open(CACHE_FILE, 'r') as cache:
            if bytes(username, 'utf-8') in cache.keys():
                cache_pass_str = cache[username].decode('utf-8')
                return cache_pass_str.strip()
    except (IOError, OSError) as e:
        print(f"Could not open the dbm file: {e}", file=sys.stderr)
        sys.exit()
    return None

def check_user_password_match(users_list, user_to_search):
    # Returns whether there is a match with user's password in both the user list and the cache
    try:
        with dbm.open(CACHE_FILE, 'r') as cache:
            # Have to convert the username string to bytes for the check since the cache is in bytes
            if bytes(user_to_search, 'utf-8') in cache.keys():
                cache_pass_str = cache[user_to_search].decode('utf-8') # Convert the password that is in bytes to string
                return users_list[user_to_search].strip() == cache_pass_str.strip()
    except (IOError, OSError) as e:
        print(f"Could not open the dbm file: {e}", file=sys.stderr)
        sys.exit()

def update_cached_password(username, new_password):
    # Updates the dbm cache for a single user with a new password, and outputs the updated password
    try:
        with dbm.open(CACHE_FILE, 'w') as cache:
            cache[username] = new_password
            print(new_password)
    except (IOError, OSError) as e:
        print(f"Could not open the dbm file: {e}", file=sys.stderr)
        sys.exit()

def main():
    # Read in and store the users list as a dict for reference
    # users_list = get_users_list(USERS_LIST_FILE)

    # Update user cache
    '''for user_to_search in users_to_search:
        # Only update passwords in user cache if there is no match
        if check_user_password_match(users_list, user_to_search) is False:
            update_cached_password(user_to_search, users_list[user_to_search])'''

    # Process standard input from command line
    users_to_search = []
    for line in sys.stdin:
        user = line.strip()
        users_to_search.append(user)

    for user_to_search in users_to_search:
        new_password = get_password(user_to_search)
        #print("new password: " + new_password)
        cached_password = get_cached_password(user_to_search)
        #print("cached password: " + cached_password)
        if new_password != cached_password and cached_password is not None:
            update_cached_password(user_to_search, new_password)


if __name__ == "__main__":
    main()