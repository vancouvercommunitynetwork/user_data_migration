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

def check_user_pass_match(users_list, users_to_search):
    # Checks if the passwords in the cache match to the current user list
    # If they don't match, update each non-matching user password and print the updated password
    with dbm.open(CACHE_FILE, 'r') as cache: 
        for user_to_search in users_to_search:
            # check that the user is in the users list and the cache before checking anything else
            if user_to_search in users_list and bytes(user_to_search, 'utf-8') in cache:
                
                cache_pass_str = cache[user_to_search].decode('utf-8') # convert bytes to string
                # check if passwords don't match, and make the update
                if users_list[user_to_search].strip() != cache_pass_str.strip():
                    # print("not a match, USER LIST PASS: " + users_list[user_to_search] + ", CACHE USER PASS: " + cache_pass_str)
                    # MAKE UPDATE HERE
                    update_cache_user_pass(user_to_search, users_list[user_to_search])

def update_cache_user_pass(username, new_password):
    # Updates the dbm cache for a single user with a new password, and outputs it
    with dbm.open(CACHE_FILE, 'w') as cache:
        cache[username] = new_password
        print(new_password)

def main():
    # Read in and store the users list as a dict for reference
    users_list = get_users_list(USERS_LIST_FILE)

    # Process standard input from command line
    users_to_search = []
    for line in sys.stdin:
        user = line.strip()
        users_to_search.append(user)

    check_user_pass_match(users_list, users_to_search)

if __name__ == "__main__":
    main()