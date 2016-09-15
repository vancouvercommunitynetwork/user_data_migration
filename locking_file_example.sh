#!/usr/bin/env bash

# This script is an example of doing file locking, but these functions will only block other scripts that also use these functions. Using these functions to lock a file will not stop any other process from messing with those files despite your locking.


lockFile() {
    local file_to_lock=$1
    eval "exec {lf_file_handle}>>$file_to_lock"
    flock -n $lf_file_handle || {
        echo "ERROR: Unable to lock file: $file_to_lock"
        exit 1
    }
    result=$lf_file_handle
}

unlockFile() {
    local file_descriptor_to_unlock=$1
    eval "exec $file_descriptor_to_unlock>&-"
}

lockFile foo.txt
file_handle=$result

echo Handle is $file_handle

sleep 2
echo garbage >> foo.txt

unlockFile $file_handle

