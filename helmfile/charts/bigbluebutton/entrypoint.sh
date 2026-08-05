#!/bin/bash
set -e

mkdir -p /var/run/shibboleth

if [ -f /etc/shibboleth/shibboleth2.xml ]; then
    /usr/sbin/shibd -f &
    echo "Shibboleth daemon started"
else
    echo "No shibboleth2.xml found - skipping Shibboleth daemon startup"
fi

# Start Greenlight's Puma server in the background
cd /opt/greenlight

if [ "${RAILS_FORCE_SSL}" = "false" ]; then
    sed -i 's/config.force_ssl = true/config.force_ssl = false/' config/environments/production.rb
fi

echo "Starting Greenlight Puma server..."
bundle exec puma -C config/puma.rb &
PUMA_PID=$!

# Wait for Puma to be ready
echo "Waiting for Puma to start..."
sleep 5

# Check if Puma is still running
if ! kill -0 $PUMA_PID 2>/dev/null; then
    echo "ERROR: Puma failed to start"
    exit 1
fi

echo "Puma started successfully (PID: $PUMA_PID)"

# Start Apache in the foreground (this will block)
exec "$@"
