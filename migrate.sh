#!/usr/bin/env bash

# Lockout simulataneous execution of this script.
exec 200>"/var/run/vcn_user_data_migration.lck"
flock -n 200 || {
    echo "ERROR: A previous instance of $(basename $0) is already running."
    exit 1
}
echo $$ 1>&200

# For each user...
while read user_name; do
    # Try to get user's data from /etc/passwd and /etc/shadow.
    passwd_result=$(grep "^$user_name:" /etc/passwd)
    shadow_result=$(grep "^$user_name:" /etc/shadow)

    # If user's data was found...
    if [ ! -z "$passwd_result" ] && [ ! -z "$shadow_result" ]; then
        # Split entry components into arrays of fields.
        IFS=':' read -r -a passwd_fields <<< "$passwd_result"
        IFS=':' read -r -a shadow_fields <<< "$shadow_result"

        # Pull the needed fields from the arrays. The field ordering in passwd and shadow are:
        #    username:password:userID:groupID:gecos:homeDir:shell
        #    username:password:lastchanged:minimum:maximum:warn:inactive:expire
        name=${passwd_fields[0]}   # Username.
        pass=${shadow_fields[1]}   # User's encrypted password.
        gid=${passwd_fields[3]}    # User's group ID.
        gecos=${passwd_fields[4]}  # User's info (full name).
        shell="/sbin/nologin"      # Shell disabled for security.        

        # Remotely add user accounts (ssh will halt loop without -n).
        echo Migrating user: $name
        ssh -n $1 deluser $name
        ssh -n $1 /usr/sbin/useradd -p \'$pass\' -g $gid -c \"$gecos\" -M -s $shell $name
    fi
done <"$2"

