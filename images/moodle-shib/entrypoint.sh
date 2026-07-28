#!/bin/sh
set -e

mkdir -p /run/shibboleth /var/run/shibboleth

if [ -d /var/www/moodledata ]; then
    chown -R www-data:www-data /var/www/moodledata 2>/dev/null || true
fi

shibd -f -p /run/shibboleth/shibd.pid 2>&1 &

for i in 1 2 3 4 5 6 7 8 9 10; do
    if [ -S /run/shibboleth/shibd.sock ]; then
        echo "shibd started successfully (socket ready)"
        break
    fi
    echo "Waiting for shibd socket... ($i)"
    sleep 1
done

if [ ! -S /run/shibboleth/shibd.sock ]; then
    echo "WARNING: shibd socket not available after 10 seconds, starting Apache anyway"
fi

exec apache2ctl -D FOREGROUND
