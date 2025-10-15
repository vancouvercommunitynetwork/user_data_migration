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

def load_cache(file_path):
    # Load the JSON cache data into a dictionary to be updated/saved later
    file_cache = {}

    try:
        # Load the cache if the cache file already exists
        with open(file_path, 'r') as file:
            file_cache = json.load(file)
        return file_cache
    except (IOError, OSError, json.JSONDecodeError):
        return {}
    
def update_cache(cache_data, users_list, users_to_search):
    # Updates the user cache data dictionary. 
    # Finds the corresponding user in the full users list and their password.
    # The cache data gets updated with the username/password pair
    updated_user_cache = cache_data

    for search_user in users_to_search:
        if search_user in users_list:
            # Create/update the username/password pair and add to updated cache
            updated_user_cache[search_user] = users_list[search_user]

    return updated_user_cache

def save_cache(cache_data, file_path):
    # Saves cache data to a JSON file. Creates a new cache file if it doesn't exist yet.
    try:
        with open(file_path, 'w') as file:
            json.dump(cache_data, file, indent=2)
    except (IOError, OSError) as e:
        print(f"Could not save cache file: {e}", file=sys.stderr)

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

    # Load cache from file
    #user_cache = load_cache(CACHE_FILE)

    # Update cache data
    #updated_user_cache = update_cache(user_cache, users_list, users_to_search)

    # Save the cache data to a JSON cache file
    #save_cache(updated_user_cache, CACHE_FILE)
    

if __name__ == "__main__":
    main()