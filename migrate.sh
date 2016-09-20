#!/usr/bin/env bash

# Rough draft
#If argc != 3 or --help given then output the usage method.
#If pre-authorized ssh access is unavailable at the source and/or destination then prompt for the password so it can be setup.
#Read the source passwd and shadow files into an internal array of user data.
#Iterate through the array executing useradd remotely at the destination.


#For each username in list_of_users:
#    $passwd_result = grep /etc/passwd
#    $shadow_result = grep /etc/shadow
#    if passwd_result and shadow_result are both not null:
#        split the passwd_result into its fields
#        split the shadow_result into its fields
#        use ssh to call useradd on remote machine with the extracted fields




clear
while read user_name; do
    # Get user entries from /etc/passwd and /etc/shadow.
    passwd_result=$(grep "^$user_name:" /etc/passwd)
    shadow_result=$(grep "^$user_name:" /etc/shadow)

    # If user entries were found extract data from them.
    if [ ! -z "$passwd_result" ] && [ ! -z "$shadow_result" ]; then
        IFS=':' read -r -a passwd_fields <<< "$passwd_result"
        IFS=':' read -r -a shadow_fields <<< "$shadow_result"
        echo Migrating user: ${passwd_fields[0]}
        # /etc/passwd entries are indexed as username:password:userID:groupID:gecos:homeDir:shell
        ssh -n $1 /usr/sbin/useradd -u ${passwd_fields[2]} -g ${passwd_fields[3]} -c \"${passwd_fields[4]}\" -M -s "/sbin/nologin" ${passwd_fields[0]}
        # /etc/shadow are entries indexed as username:password
    fi
done <"$2"

exit 0

