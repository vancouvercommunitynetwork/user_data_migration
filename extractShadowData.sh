#!/bin/bash

# A pipeable script for extracting a subset of /etc/shadow for user migration purposes.

# Indices of data members in an /etc/shadow entry.
index_user=0  # The login name
index_password=1  # The encrypted password
index_last_password_change=2  # Days since Jan 1, 1970 that password was last changed
index_minimum=3  # The minimum number of days required between password changes
index_maximum=4  # The maximum number of days the password is valid
index_warn=5  # The number of days before password is to expire that user is warned that his/her password must be changed
index_inactive=6  # The number of days after password expires that account is disabled
index_expire=7  # days since Jan 1, 1970 that account is disabled


case "$1" in
    "--help")
        echo "A pipeable script for extracting encrypted passwords from /etc/shadow."
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help   display this message"
        echo "  -r       report missing users to stderr"
        exit 0
    ;;
    "-r")
        reportMissingUsers="true"
    ;;
esac

# Read usernames to extract passwords for.
while read user_name; do
    # Search for username in /etc/shadow
    user_result=$(grep "^$user_name:" /etc/shadow) # Entry line must start with username followed by a colon in order to match.
    
    # If a match was found then process it.
    if [ ! -z $user_result ]; then
        # Split the user's entry by colons into an array.
        IFS=':' read -r -a array_of_field_data <<< "$user_result"

        # Take the required entries and ignore the rest.
        field_user=${array_of_field_data[index_user]}
        field_password=${array_of_field_data[index_password]}

        # Output reconstructed (user:password) pairs.
        user_entry="$field_user:$field_password"
        echo $user_entry
    else
        if [ "$reportMissingUsers" == true ]; then
            # Report missing users to file descriptor #2 (stderr).
            >&2 echo "  No record was found for user: $user_name"
        fi
    fi
done

