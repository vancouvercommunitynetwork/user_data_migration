#!/usr/bin/env bash

lockFile() {
    local file_to_lock=$1
    eval "exec {lf_file_handle}>>$file_to_lock"
    eval "exec $lf_file_handle>>$file_to_lock"
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

echo garbage >> foo.txt
sleep 2

unlockFile $file_handle

