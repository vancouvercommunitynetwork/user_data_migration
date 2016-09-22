# User Data Migration

## Usage:
### Usage: ./migrate.sh [DESTINATION] [USER LIST FILE]
### Migrate users from this machine to a remote machine. The user list must be a text file containing a newline-separated list of usernames. The network destination needs to be pre-authorized for ssh access which can be done with ssh-keygen.
### 
### Example:
###   ./migrate.sh root@192.168.1.257 bunch_of_users.txt

## History
#### A number of scripts were in this project that ended up being moved to the folder labelled "deprecated". New scripts such as importUsers.sh and exportUsers.sh were experimented with but then set aside for a different approach to the problem. The current working version of this software consists entirely of a single script called migrate.sh. This program uses pre-authorized ssh access to remotely call deluser and useradd in order to migrate new users to the remote machine and update users that pre-exist on the remote machine. Time-profiling has shown this to be an approach of limited usefullness. Current measurements show the script taking 16 minutes to migrate 1000 users which would extrapolate to a 4 hour runtime to migrate 15,000 users. Other approaches are being investigated. See the pyMigrate project for further work.

## Program Assumptions
### This program takes a list of usernames and copies the user accounts to a specified remote machine. The following assumptions are made about how it will be used:
###  - This program will be run regularly, possibly as a cron job. It must run reasonably quickly and prevent more than one instance from running at one time.
###  - The list of usernames will grow to be a large file consisting primarily of redundant users who already exist on the remote machine but must be updated in case their information has changed (their password in particular).

## Program Requirements
###  - This program must be run as the superuser so it can access /etc/passwd, /etc/shadow and execution lock file that prevents more than one instance from running.
###  - This program must be pre-authorized for ssh access on the remote machine using ssh-keygen.
###  - Pre-authorized access must be connecting to the superuser account on the remote machine so it can remotely alter user accounts.
###  - Locale forwarding should be disabled to prevent ssh error messages if local and remote locale information differs (comment out SendEnv in the local /etc/ssh/ssh_config or AcceptEnv in the remote machine's /etc/ssh/ssh_config). The program will still work if you don't take care of this but a ton of warnings will be getting dumped to the local machine if the locales don't match.
###  - Users that are being transferred will retain their group ID. That group ID must already exist at the destination machine.

## Program Issues
###    Several operational requirements must be met for this program to execute correctly. The program checks for as many of these as possible but some unforseen circumstances may cause remotely executed commands to fail which can potentially cause this program to generate thousands of errors (one per user).
###  - Parts of this program may make use of the deluser command while supressing the output of the command. The deluser command currently has a bug causing it throw a warning that a deleted user was the last member of its group even though it was not and these erroneous warnings clutter up the valid output of the program. To avoid this the deluser stdout and stderr are redirected to purgatory (/dev/null). Bug documentation is available here:
###     https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=473379
###  - Transferred users do not presently retain their user ID number. Linux uniquely identifies user accounts by their username but will allow duplicate user IDs. These ID collisions may cause unexpected problems elsewhere in OS operation. To avoid that outcome the program asks the remote system to provide a unique ID each time a user is transferred/updated. The program can be relied upon to not create UID collisions but the user accounts cannot be relied upon to have static UIDs on the remote machine.

