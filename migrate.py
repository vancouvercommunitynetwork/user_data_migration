import sys

def read_user_list(user_list_file):
    # Store usernames/passwords for reference in a dictionary
    users = {}

    try:
        with open(user_list_file, 'r') as file:
            for line in file:
                user = line.strip()
                if user:
                    split_user = user.split(":")
                    username = split_user[0]
                    password = split_user[1]
                    users[username] = password
            return users
    except (IOError, OSError) as e:
        print(f"Error reading user list file: {e}", file=sys.stderr)
        sys.exit()

def print_users(users):
    for key, value in users.items():
        print("Username: " + key + ", Password: " + value)

def main():
    destination = sys.argv[1] # currently unused but will be needed later
    user_file = sys.argv[2]

    # Read in a users list, and store users for reference
    users = read_user_list(user_file)

    print_users(users)

if __name__ == "__main__":
    main()