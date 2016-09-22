#!/usr/bin/env bash

# This script is meant to be run remotely on the destination machine to import the user data that has been copied over. It is not intended to be run manually, but it can be.
 
set -e  # Exit script on command failures.
set -u  # Exit script on attempted use of undeclared variables.

# Check that command arguments are correct.
if [ $# -ne 2 ]; then
    echo "A script for importing a list of users from a field in the same format as an /etc/passwd file."
    echo "Usage: $0 <passwd file> <shadow file>"
fi

# Indices of data members in an /etc/passwd entry.
index_user=0
index_password=1
index_uid=2
index_gid=3
index_gecos=4
index_dir=5
index_shell=6

# Read in the new users and create their accounts.
# NOTE: User importing is implemented with a loop because the newusers command has a bug that under hard-to-control circumstances will crash with an "invalid next size" error message. Documentation of this bug is available at: https://bugs.launchpad.net/ubuntu/+source/shadow/+bug/1266675
echo "REMOTE: Adding new users."
while read line; do
    # Split the user's entry by colons into an array.
    IFS=':' read -r -a array_of_field_data <<< "$line"

    # Convert the array to a set of fields.
    field_user=${array_of_field_data[index_user]}
    field_password=${array_of_field_data[index_password]}
    field_uid=${array_of_field_data[index_uid]}
    field_gid=${array_of_field_data[index_gid]}
    field_gecos=${array_of_field_data[index_gecos]}
    field_dir=${array_of_field_data[index_dir]}
    field_shell=${array_of_field_data[index_shell]}

    # Create the new user (do not create a home directory) and OR with true so "set-e" won't halt the script if a duplicate user is encountered.
    echo "REMOTE: Adding user $line"
    useradd -u $field_uid -g $field_gid -c "$field_gecos" -M -s $field_shell $field_user || true
done <$1

echo "REMOTE: Migrating passwords."
chpasswd -e < $2

