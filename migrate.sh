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
        # /etc/passwd fields are indexed as username:password:userID:groupID:gecos:homeDir:shell
        IFS=':' read -r -a passwd_fields <<< "$passwd_result"
        # /etc/shadow fields are indexed as username:password:lastchanged:minimum:maximum:warn:inactive:expire
        IFS=':' read -r -a shadow_fields <<< "$shadow_result"

        echo Migrating user: ${passwd_fields[0]}

        # Remotely add user accounts (ssh will halt loop without -n). See above for index meanings. Users are not intended to have shell login.
        ssh -n $1 /usr/sbin/useradd -p \'${shadow_fields[1]}\' -g ${passwd_fields[3]} -c \"${passwd_fields[4]}\" -M -s "/sbin/nologin" ${passwd_fields[0]}
    fi
done <"$2"

exit 0


Current ideas
    figure out how the useradd -p is supposed to work 
    call chpasswd -e and find someway to feed a string into it as if it were a file
        this must be able to work because it works for exportUsers.sh. "chpass -e < tempShadow.txt" creates an account that I can then "su - test8" into (from test9) and it will prompt for password and the password works.
        <<< doesn't seem to work the way I thought it does
        
