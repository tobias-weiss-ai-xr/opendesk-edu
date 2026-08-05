#!/bin/sh
set -e

# Start shibd daemon in the background
shibd -f &

# Wait briefly for shibd socket to be ready
for i in 1 2 3 4 5 6 7 8 9 10; do
    if [ -S /run/shibboleth/shibd.sock ]; then
        echo "shibd started successfully (socket ready)"
        break
    fi
    echo "Waiting for shibd socket... ($i)"
    sleep 1
done

# If shibd failed to start, try to continue anyway
if [ ! -S /run/shibboleth/shibd.sock ]; then
    echo "WARNING: shibd socket not available after 10 seconds, starting Apache anyway"
fi

# Start Apache as PID 1 (foreground)
# Ignore any arguments passed by the Helm chart command override
exec apache2-foreground
