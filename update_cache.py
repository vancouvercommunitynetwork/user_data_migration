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
    file_cache = {}

    try:
        with open(file_path, 'r') as file:

            file_content = json.load(file)

            file_cache[file_path] = file_content

            return file_cache[file_path]
    except (IOError, OSError, json.JSONDecodeError):
        return {}

def save_cache(file_path):
    test_data = {'user1': 'pass1',
                 'user2': 'pass2'}
    with open(file_path, 'w') as file:
        json.dump(test_data, file)

def main():
    # Read in and store the users list as a dict for reference
    users = get_users_list(USERS_LIST)

    # Process input
    for line in sys.stdin:
        user = line.strip()

    user_cache = load_cache(CACHE_FILE)
    # print(user_cache)
    
    save_cache(CACHE_FILE)

if __name__ == "__main__":
    main()