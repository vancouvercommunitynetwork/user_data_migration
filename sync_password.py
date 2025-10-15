import sys
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

def main():
    # Read in and store the users list as a dict for reference
    users_list = get_users_list(USERS_LIST_FILE)

if __name__ == "__main__":
    main()