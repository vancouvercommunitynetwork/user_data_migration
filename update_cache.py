import sys
import json

# Existing list of users, assuming the file is in the same directory as this script
USERS_LIST = "test_users.txt"

CACHE_FILE = "user_cache.json"

def get_users_list(user_list_file):
    # Store usernames/passwords for reference in a dictionary
    users = {}

    try:
        with open(user_list_file, 'r') as file:
            for line in file:
                user = line.strip()
                if user:
                    username, password = user.split(":")
                    users[username] = password # store username and password
            return users
    except (IOError, OSError) as e:
        print(f"Error reading user list file: {e}", file=sys.stderr)
        sys.exit()

def load_cache(file_path):
    # Load the cache data into a dictionary which will be updated later
    file_cache = {}

    try:
        # Load the cache if the cache file already exists
        with open(file_path, 'r') as file:
            file_content = json.load(file)
            file_cache[file_path] = file_content
            return file_cache[file_path]
    except (IOError, OSError, json.JSONDecodeError):
        return {}
    
def update_cache(cache_data, users_list, users_to_search):
    # Updates the user cache data dictionary. Finds the corresponding user in the full users list and their password.
    # The cache data gets updated with the username/password pair
    updated_user_cache = cache_data

    for search_user in users_to_search:
        if search_user in users_list:
            cache_data[search_user] = users_list[search_user]

    return updated_user_cache

def save_cache(cache_data, file_path):
    #cache_data = {'user1': 'pass1',
    #             'user2': 'pass2'}
    
    try:
        with open(file_path, 'w') as file:
            json.dump(cache_data, file, indent=2)
    except (IOError, OSError) as e:
        print(f"Could not save cache file: {e}", file=sys.stderr)

def main():
    # Read in and store the users list as a dict for reference
    users_list = get_users_list(USERS_LIST)

    # Process input
    users_to_search = []
    for line in sys.stdin:
        user = line.strip()
        users_to_search.append(user)

    # Load cache from file
    user_cache = load_cache(CACHE_FILE)

    user_cache = update_cache(user_cache, users_list, users_to_search)

if __name__ == "__main__":
    main()