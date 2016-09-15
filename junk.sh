#!/usr/bin/env bash
 
 
lock="/var/run/vcn_user_data_migration.lck"

lockFailureExit(){
    echo "Instance already running!"
    exit 1
}

exec 200>$lock
flock -n 200 || lockFailureExit
 
echo $$ 1>&200
sleep 2
echo
echo "Hello world"
