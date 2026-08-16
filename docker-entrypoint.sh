#!/bin/sh
set -e

# If /etc/aprx.conf does not exist, copy template
if [ ! -f /etc/aprx.conf ]; then
    echo "[aprx-docker] /etc/aprx.conf not found. Initializing from default template..."
    cp /etc/aprx.conf.default /etc/aprx.conf
fi

# Ensure log directory exists
mkdir -p /var/log/aprx

# If first arg starts with a dash or is empty, run aprx with flags
if [ $# -eq 0 ] || [ "${1#-}" != "$1" ]; then
    exec /usr/sbin/aprx -i -f /etc/aprx.conf "$@"
fi

# If first arg is aprx, exec it with provided args
if [ "$1" = "aprx" ]; then
    shift
    exec /usr/sbin/aprx -i -f /etc/aprx.conf "$@"
fi

# Otherwise execute custom command (e.g. aprx-stat, sh, bash)
exec "$@"
