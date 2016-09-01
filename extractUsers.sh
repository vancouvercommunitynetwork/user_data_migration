#!/bin/bash

# An alternate version of extractUserData.sh that calls extractPasswdData.sh and extractShadowData.sh.

if [ $# -ne 3 ]; then
    echo "Usage: $0 <input file> <user data output file> <user password output file>"
    echo
    echo "Explanation"
    echo "  An username input file is required. It must contain a list of newline-separated usernames."
    echo "  A user data output file is required. It will be overwritten with user entries derived from /etc/passwd."
    echo "  A user password output file is required. It will be overwritten with encrypted password entries from /etc/shadow."
    exit 1
fi

echo "Extracting user data for users specified by input file: $1"
./extractPasswdData.sh < $1 > $2

echo "Extracting passwords for users specified by input file: $1"
./extractShadowData.sh < $1 > $3
