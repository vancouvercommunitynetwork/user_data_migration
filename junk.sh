#!/usr/bin/env bash
 
set -e  # Exit script on command failures.
set -u  # Exit script on attempted use of undeclared variables.
 
lock="/var/run/vcn_user_data_migration.lck"

exec 200>$lock
flock -n 200 || exit 1
 
echo $$ 1>&200
sleep 4
echo "Hello world"
