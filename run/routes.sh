#!/usr/bin/env bash
SCRIPTDIR="$(dirname "$(realpath "$0")")"
source "${SCRIPTDIR}"/config.txt

# Add or delete the routes found in config.txt

# Syntax for this script:
# ./routes.sh [add|del]

if [ $# -gt 0 ]
then
    ARG="$1"
else
    echo 'syntax is `routes.sh [add|del]`'
    exit
fi

if [[ ${ARG,,} =~ ^a ]] 
then
    OPERATION='add'
elif [[ ${ARG,,} =~ ^d ]] 
then
    OPERATION='del'
else
    echo 'syntax is `routes.sh [add|del]`'
    exit
fi

# Add or delete each route
IFS=',' # Internal Field Separator
for ROUTE in $ROUTES
do 
    sudo ip route "$OPERATION" "$ROUTE" via "$GATEWAY"
done
