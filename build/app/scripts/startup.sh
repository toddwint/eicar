#!/usr/bin/env bash

## Run the commands to make it all work
ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

echo $HOSTNAME > /etc/hostname

# Extract compressed binaries and move binaries to bin
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    # Unzip frontail and tailon
    if [[ $(arch) == "x86_64" ]]; then
        gunzip /usr/local/bin/frontail.gz
    fi
    gunzip /usr/local/bin/tailon.gz

    # Copy python scripts to /usr/local/bin and make executable
    cp /opt/"$APPNAME"/scripts/menu /usr/local/bin
    chmod 775 /usr/local/bin/menu
fi

# Link scripts to debug folder as needed
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    ln -s /opt/"$APPNAME"/scripts/tail.sh /opt/"$APPNAME"/debug
    ln -s /opt/"$APPNAME"/scripts/tmux.sh /opt/"$APPNAME"/debug
    ln -s /opt/"$APPNAME"/scripts/menu /opt/"$APPNAME"/debug
fi

# Create the file /var/run/utmp or when using tmux this error will be received
# utempter: pututline: No such file or directory
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    touch /var/run/utmp
else
    truncate -s 0 /var/run/utmp
fi

# Link the log to the app log. Create/clear other log files.
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    mkdir -p /opt/"$APPNAME"/logs
    touch /opt/"$APPNAME"/logs/"$APPNAME".log
    touch /opt/"$APPNAME"/logs/webfsd.log
    chown www-data:www-data /opt/"$APPNAME"/logs/webfsd.log
else
    truncate -s 0 /opt/"$APPNAME"/logs/"$APPNAME".log
    truncate -s 0 /opt/"$APPNAME"/logs/webfsd.log
fi

# Print first message to either the app log file or syslog
echo "$(date -Is) [Start of $APPNAME log file]" >> /opt/"$APPNAME"/logs/"$APPNAME".log
#logger "[Start of $APPNAME log file]"

# Check if `public` subfolder exists. If non-existing, create it .
# Checking for a file inside the folder because if the folder
#  is mounted as a volume it will already exists when docker starts.
# Also change permissions
if [ ! -e "/opt/$APPNAME/public/.exists" ]
then
    mkdir -p /opt/"$APPNAME"/public
    touch /opt/"$APPNAME"/public/.exists
    echo '`public` folder created'
    chown -R "${HUID}":"${HGID}" /opt/"$APPNAME"/public
fi


# Modify configuration files or customize container
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    # Create the EICAR test virus
    # https://www.eicar.org/download-anti-malware-testfile/
    echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H' > /opt/"$APPNAME"/public/eicar.com
    sed -i 's/.*/&*/' /opt/"$APPNAME"/public/eicar.com
    truncate -s -1 /opt/"$APPNAME"/public/eicar.com
    cp /opt/"$APPNAME"/public/eicar.com /opt/"$APPNAME"/public/eicar.com.txt
    tar -C /opt/"$APPNAME"/public/ -czf "eicar.tar.gz" eicar.com eicar.com.txt
    tar -C /opt/"$APPNAME"/public/ -cjf "eicar.tar.bz2" eicar.com eicar.com.txt
    tar -C /opt/"$APPNAME"/public/ -cJf "eicar.tar.xz" eicar.com eicar.com.txt
    mv eicar.tar.gz eicar.tar.bz2 eicar.tar.xz /opt/"$APPNAME"/public/

    # Make copies of template files
    cp /opt/"$APPNAME"/configs/webfsd.conf.template /opt/"$APPNAME"/configs/webfsd.conf

    # webfsd template modifications
    sed -Ei '/^web_root=/c web_root="/opt/'"$APPNAME"'/public"' /opt/"$APPNAME"/configs/webfsd.conf
    sed -Ei '/^web_accesslog=/c web_accesslog="/opt/'"$APPNAME"'/logs/webfsd.log"' /opt/"$APPNAME"/configs/webfsd.conf

    # Copy templates to configuration locations
    cp /opt/"$APPNAME"/configs/webfsd.conf /etc/webfsd.conf
    cp /opt/"$APPNAME"/configs/tmux.conf /root/.tmux.conf

    # Create menu.json
    /opt/"$APPNAME"/scripts/make_menujson.py /opt/"$APPNAME"/scripts/menu.json
fi

# Print location of files to user
echo "Here are the eicar files on the server" >> /opt/"$APPNAME"/logs/"$APPNAME".log
ls /opt/"$APPNAME"/public/*eicar* >> /opt/"$APPNAME"/logs/"$APPNAME".log
echo "You can download them by going to http://${IPADDR}:80" >> /opt/"$APPNAME"/logs/"$APPNAME".log

# Start services
service webfs start

# Start web interface
NLINES=1000 # how many tail lines to follow
sed -Ei 's/tail -n 500/tail -n '"$NLINES"'/' /opt/"$APPNAME"/scripts/tail.sh
sed -Ei 's/tail -n 500/tail -n '"$NLINES"'/' /opt/"$APPNAME"/scripts/tmux.sh
sed -Ei 's/\$lines/'"$NLINES"'/' /opt/"$APPNAME"/configs/tailon.toml
sed -Ei '/^listen-addr = /c listen-addr = [":'"$HTTPPORT4"'"]' /opt/"$APPNAME"/configs/tailon.toml

# ttyd1 (tail and read only)
nohup ttyd \
    --port "$HTTPPORT1" \
    --client-option titleFixed="${APPNAME}.log" \
    --client-option fontSize=16 \
    --client-option 'theme={"foreground":"black","background":"white","selectionBackground":"#ff6969"}' \
    --signal 2 /opt/"$APPNAME"/scripts/tail.sh \
    >> /opt/"$APPNAME"/logs/ttyd1.log 2>&1 &

# ttyd2 (tmux and interactive)
nohup ttyd \
    --writable \
    --port "$HTTPPORT2" \
    --client-option titleFixed="${APPNAME}.log" \
    --client-option fontSize=16 \
    --client-option 'theme={"foreground":"black","background":"white","selectionBackground":"#ff6969"}' \
    --signal 9 \
    /opt/"$APPNAME"/scripts/tmux.sh \
    >> /opt/"$APPNAME"/logs/ttyd2.log 2>&1 &

# frontail
if [[ $(arch) == "x86_64" ]]; then
    nohup frontail \
        -n "$NLINES" \
        -p "$HTTPPORT3" \
        /opt/"$APPNAME"/logs/"$APPNAME".log \
        >> /opt/"$APPNAME"/logs/frontail.log 2>&1 &
fi

# tailon
nohup tailon \
    -c /opt/"$APPNAME"/configs/tailon.toml \
    /opt/"$APPNAME"/logs/"$APPNAME".log \
    /opt/"$APPNAME"/logs/ttyd1.log \
    /opt/"$APPNAME"/logs/ttyd2.log \
    /opt/"$APPNAME"/logs/frontail.log \
    /opt/"$APPNAME"/logs/tailon.log \
    >> /opt/"$APPNAME"/logs/tailon.log 2>&1 &

# Remove the .firstrun file if this is the first run
if [ -e /opt/"$APPNAME"/scripts/.firstrun ]; then
    rm -f /opt/"$APPNAME"/scripts/.firstrun
fi

# Keep docker running
bash
