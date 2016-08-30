#!/bin/bash

# An alternate version of extractUserData.sh

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input file> <output file>"
    echo
    echo "Explanation"
    echo "  An input file is required. It must contain a list of newline-separated usernames."
    echo "  An output file is required. It will be overwritten with found user entries."
    exit 1
fi

# Delete the output file to prevent appending of duplicate entries.
#rm $2

echo "Processing user list: $1"

./extractUserData2.sh < $1 > $2
