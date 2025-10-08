import sys

# Existing list of users, assuming the file is in the same directory as this script
USERS_LIST = "test_users.txt" 

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

def search_users(users, user_list_search_file):
    # Reads in the file with users to search for in the users dict
    # Users to search for are stored into an array
    users_to_search = []

    try:
        with open(user_list_search_file, 'r') as file:
            for line in file:
                users_to_search.append(line.strip())
    except (IOError, OSError) as e:
        print("Error reaching user search file: {e}", file=sys.stderr)
        sys.exit()

    for search_user in users_to_search:
        # print each user that exists
        if search_user in users:
            print(search_user)

def main():
    # Get command line arguments
    user_search_file = sys.argv[1]

    # Read in and store an already existing list of users to a dict for search reference
    users = get_users_list(USERS_LIST)

    # Read in a list of users to search for provided in the command line arguments and find matches in the existing user list
    search_users(users, user_search_file)

if __name__ == "__main__":
    main()