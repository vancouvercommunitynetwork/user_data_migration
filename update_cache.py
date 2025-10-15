import sys
import json
import dbm

# Existing list of users, assuming the file is in the same directory as this script
USERS_LIST_FILE = "test_users.txt"
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

def update_user_cache(users_list, user_to_search):
    # Reads and updates the dbm cache for a single user
    if user_to_search in users_list:  
        try:
            # Create new cache if it currently doesn't exist
            with dbm.open(CACHE_FILE, 'c') as cache: 
                cache[user_to_search] = users_list[user_to_search]
        except (IOError, OSError) as e:
            print(f"Could not open the dbm file: {e}", file=sys.stderr)
 
def main():
    # Read in and store the users list as a dict for reference
    users_list = get_users_list(USERS_LIST_FILE)

    # Process standard input from command line
    users_to_search = []
    for line in sys.stdin:
        user = line.strip()
        users_to_search.append(user)

    # Updates user cache for each searched user
    for user_to_search in users_to_search:
        update_user_cache(users_list, user_to_search)

if __name__ == "__main__":
    main()