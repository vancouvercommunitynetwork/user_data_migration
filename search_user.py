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
                    # Store username and password
                    users[username] = password
            return users
    except (IOError, OSError) as e:
        print(f"Error reading user list file: {e}", file=sys.stderr)
        sys.exit()

def search_users(input, users):
    # Search for users from the user list if they exist based on usernames passed as input
    found_users = []

    for line in input:
        search_user = line.strip()
        if search_user in users:
            found_users.append(search_user)
    return found_users

def main():
    # Read in and store an already existing list of users to a dict for search reference
    users = get_users_list(USERS_LIST)

    # Process lines from piping
    found_users = search_users(sys.stdin, users)   
    for found_user in found_users:
        print(found_user)

if __name__ == "__main__":
    main()