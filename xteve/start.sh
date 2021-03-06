#!/bin/bash

# Check for missing Group / PGID
PGROUPNAME=xteve
if [ -e "${PGID}" ]
then
    echo "PGID not set, defaulting to 100" | ts '%Y-%m-%d %H:%M:%.S'
    PGID=100
fi
/bin/egrep  -i "^${PGID}:" /etc/passwd
if [ $? -eq 0 ]; then
   echo "A group with PGID $PGID already exists in /etc/passwd, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
else
   echo "A group with PGID $PGID does not exist, adding a group called 'xteve' with PGID $PGID" | ts '%Y-%m-%d %H:%M:%.S'
   groupadd -g $PGID $PGROUPNAME
fi

# Check for missing User / PUID
PUSERNAME=xteve
if [ -e "${PUID}" ]
then
    echo "PUID not set, defaulting to 99" | ts '%Y-%m-%d %H:%M:%.S'
    PUID=99
fi
/bin/egrep  -i "^.+:${PUID}:" /etc/passwd
if [ $? -eq 0 ]; then
   echo "An user with PUID $PUID already exists in /etc/passwd, nothing to do." | ts '%Y-%m-%d %H:%M:%.S'
   PUSERNAME=$(/bin/egrep  -i "^.+:${PUID}:" /etc/passwd | cut -d ":" -f1)
else
   echo "An user with PUID $PUID does not exist, adding an user called 'xteve user' with PUID $PUID" | ts '%Y-%m-%d %H:%M:%.S'
   useradd -c "xteve user" -g $PGID -u $PUID $PUSERNAME -m
fi

if [[ ! -e /config/xteve ]]; then
	mkdir -p /config/xteve
fi
chown -R ${PUID}:${PGID} /config/xteve

# Set umask
export UMASK=$(echo "${UMASK}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

if [[ ! -z "${UMASK}" ]]; then
  echo "[info] UMASK defined as '${UMASK}'" | ts '%Y-%m-%d %H:%M:%.S'
else
  echo "[warn] UMASK not defined (via -e UMASK), defaulting to '002'" | ts '%Y-%m-%d %H:%M:%.S'
  export UMASK="002"
fi

if [ -z "${XTEVE_PORT}" ]
then
    XTEVE_PORT=34400
fi
echo "[info] Poxy port: ${XTEVE_PORT}" | ts '%Y-%m-%d %H:%M:%.S'

if [ -z "${XTEVE_USER}" ]
then
    XTEVE_USER=xteve
fi
echo "[info] xteve process username: ${XTEVE_USER}" | ts '%Y-%m-%d %H:%M:%.S'

echo "[debug] xteve command: 'xteve -port=${XTEVE_PORT} -config=/config/xteve &'" | ts '%Y-%m-%d %H:%M:%.S'
echo "[info] Starting xteve daemon..." | ts '%Y-%m-%d %H:%M:%.S'
su $PUSERNAME -c "xteve -port=${XTEVE_PORT} -config=/config/xteve &"

sleep 1
xtevepid=$(pgrep -o -x xteve)
echo "[info] xteve PID: $xtevepid" | ts '%Y-%m-%d %H:%M:%.S'

if [ -e /proc/$xtevepid ]; then
	while true
    do
        pgrep -o -x xteve
        if [ $? -eq 0 ]
        then
            # keep the network traffic over the vpn active (vpn providers might time us out)
            ping -c 10 8.8.8.8 2>&1 > /dev/null
            sleep 5
        else
            echo "[error] xteve died!" | ts '%Y-%m-%d %H:%M:%.S'
            exit 1
        fi
    done
else
	echo "[error] xteve failed to start!" | ts '%Y-%m-%d %H:%M:%.S'
fi