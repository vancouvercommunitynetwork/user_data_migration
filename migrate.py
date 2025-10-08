import sys

USERS_LIST = "test_users.txt" # an existing list of users

def get_users_list(user_list_file):
    # Store usernames/passwords for reference in a dictionary
    users = {}

    try:
        with open(user_list_file, 'r') as file:
            for line in file:
                user = line.strip()
                if user:
                    username, password = user.split(":")
                    users[username] = password
            return users
    except (IOError, OSError) as e:
        print(f"Error reading user list file: {e}", file=sys.stderr)
        sys.exit()

def read_user_search_list(user_list_search_file):
    # Users to search for are stored into an array
    users_to_search = []

    try:
        with open(user_list_search_file, 'r') as file:
            for line in file:
                users_to_search.append(line.strip())
            return users_to_search
    except (IOError, OSError) as e:
        print("Error reaching user search file: {e}", file=sys.stderr)
        sys.exit()

def search_users(users, users_to_search):
    for user_to_search in users_to_search:
        if user_to_search in users:
            print(user_to_search)

def main():
    user_search_file = sys.argv[1]

    # Read in and store an already existing list of users to a dict for search reference
    users = get_users_list(USERS_LIST)
    print(users)

    # Read in a list of users to search for provided in the command line arguments
    users_to_search = read_user_search_list(user_search_file)
    print(users_to_search)

    search_users(users, users_to_search)

if __name__ == "__main__":
    main()