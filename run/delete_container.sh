#!/usr/bin/env bash
SCRIPTDIR="$(dirname "$(realpath "$0")")"
source "${SCRIPTDIR}"/config.txt

# Stop and remove the container
docker container stop "$HOSTNAME"
docker container rm "$HOSTNAME"

# Delete remote network routes
IFS=',' # Internal Field Separator
for ROUTE in $ROUTES; do sudo ip route del "$ROUTE" via "$GATEWAY"; done

# Remove the IP on the interface
IPASSIGNED=$(ip addr show $INTERFACE | grep $IPADDR)
if [ -n "$IPASSIGNED" ]; then
   SETIP="$IPADDR/$(echo $SUBNET | awk -F/ '{print $2}')" 
   sudo ip addr del $SETIP dev $INTERFACE
else
    echo 'IP is not assigned to the interface'
fi

# Remove the webadmin.html customized file
rm -rf "$SCRIPTDIR"/webadmin.html
