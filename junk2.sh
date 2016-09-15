#!/usr/bin/env bash
 
 
lock="/var/run/vcn_user_data_migration.lck"

exclusiveLock() {
    # Setup lock.
    exec 200>$lock
    flock -n 200 || {
        echo "Instance already running!"
        exit 1
    }
    echo $$ 1>&200
}

# Setup lock.
#exec 200>$lock
#flock -n 200 || {
#    echo "Instance already running!"
#    exit 1
#}
#echo $$ 1>&200

exclusiveLock

sleep 2
echo
echo "Hello world"
