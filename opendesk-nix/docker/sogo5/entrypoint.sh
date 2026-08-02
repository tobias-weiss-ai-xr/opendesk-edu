#!/bin/bash
# SOGo 5 Entrypoint Script for openDesk
# Handles multi-process setup, signal handling, and graceful shutdown
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# --- LOGGING FUNCTIONS ---
log_info() {
    echo "[INFO] [$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_warn() {
    echo "[WARN] [$(date +'%Y-%m-%d %H:%M:%S')] $1" >&2
}

log_error() {
    echo "[ERROR] [$(date +'%Y-%m-%d %H:%M:%S')] $1" >&2
}

# --- SIGNAL HANDLING ---
sigo_term() {
    log_info "Received SIGTERM, shutting down gracefully..."
    kill -TERM "$SOGO_PID" 2>/dev/null || true
    kill -TERM "$MEMCACHED_PID" 2>/dev/null || true
    wait "$SOGO_PID" 2>/dev/null || true
    wait "$MEMCACHED_PID" 2>/dev/null || true
    log_info "SOGo 5 has been stopped gracefully"
    exit 0
}

sigint_term() {
    log_info "Received SIGINT, shutting down gracefully..."
    sigo_term
}

trap sigint_term SIGINT
trap sigo_term SIGTERM

# --- ENVIRONMENT VALIDATION ---
validate_env() {
    log_info "Validating environment..."
    
    # Check required environment variables
    if [ -z "${SOGO_LDAP_BIND_PASSWORD:-}" ] && [ ! -f /etc/sogo/ldap-password ]; then
        log_warn "SOGO_LDAP_BIND_PASSWORD not set, SOGo may not be able to authenticate"
    fi
    
    # Set defaults if not provided
    : "${SOGO_USER_SOURCES:=}"
    : "${SOGO_PROFILE_URL:=postgresql://sogo:sogo@postgresql.opendesk.svc:5432/sogo}"
    : "${SOGO_IMAP_SERVER:=imap.opendesk.svc}"
    : "${SOGO_SMTP_SERVER:=smtp.opendesk.svc}"
    : "${SOGO_MEMCACHED_HOST:=memcached.opendesk.svc}"
    : "${SOGO_TIMEZONE:=Europe/Berlin}"
    
    log_info "Environment validation complete"
}

# --- CONFIGURATION SETUP ---
setup_config() {
    log_info "Setting up SOGo configuration..."
    
    # Create default memcached configuration if it doesn't exist
    if [ ! -f /etc/memcached.conf ]; then
        cat > /etc/memcached.conf << 'EOF'
-m 256
-c 1024
-p 11211
-u sogo
-l 127.0.0.1
EOF
        chmod 644 /etc/memcached.conf
    fi
    
    # Create LDAP password file if environment variable is set
    if [ -n "${SOGO_LDAP_BIND_PASSWORD:-}" ] && [ ! -f /etc/sogo/ldap-password ]; then
        echo "${SOGO_LDAP_BIND_PASSWORD}" > /etc/sogo/ldap-password
        chmod 600 /etc/sogo/ldap-password
        chown sogo:sogo /etc/sogo/ldap-password
    fi
    
    # Apply environment variable overrides to sogo.conf
    if [ -n "${SOGO_USER_SOURCES:-}" ]; then
        sed -i "s|SOGoUserSources.*|SOGoUserSources = ${SOGO_USER_SOURCES};|" /etc/sogo/sogo.conf
    fi
    
    if [ -n "${SOGO_PROFILE_URL:-}" ]; then
        sed -i "s|SOGoProfileURL.*|SOGoProfileURL = \"${SOGO_PROFILE_URL}\";|" /etc/sogo/sogo.conf
    fi
    
    if [ -n "${SOGO_IMAP_SERVER:-}" ]; then
        sed -i "s|SOGoIMAPServer.*|SOGoIMAPServer = \"${SOGo_IMAP_SERVER}\";|" /etc/sogo/sogo.conf
    fi
    
    if [ -n "${SOGO_SMTP_SERVER:-}" ]; then
        sed -i "s|SOGoSMTPServer.*|SOGoSMTPServer = \"${SOGo_SMTP_SERVER}\";|" /etc/sogo/sogo.conf
    fi
    
    if [ -n "${SOGO_MEMCACHED_HOST:-}" ]; then
        sed -i "s|SOGOMemcachedHost.*|SOGOMemcachedHost = \"${SOGO_MEMCACHED_HOST}\";|" /etc/sogo/sogo.conf
    fi
    
    log_info "SOGo configuration setup complete"
}

# --- DIRECTORY SETUP ---
setup_directories() {
    log_info "Setting up directories..."
    
    # Ensure all required directories exist
    mkdir -p /var/lib/sogo /var/log/sogo /run/sogo /tmp
    
    # Set proper permissions
    chown -R sogo:sogo /var/lib/sogo /var/log/sogo /run/sogo
    chmod -R 750 /var/lib/sogo /var/log/sogo
    chmod 755 /run/sogo
    
    log_info "Directories setup complete"
}

# --- START MEMCACHED ---
start_memcached() {
    log_info "Starting memcached..."
    
    # Check if we should start memcached
    if [ "${SOGO_START_MEMCACHED:-true}" != "false" ]; then
        /usr/bin/memcached -u sogo -d -p 11211 -m 256 -c 1024 -l 127.0.0.1 &
        MEMCACHED_PID=$!
        log_info "Memcached started with PID: ${MEMCACHED_PID}"
    else
        log_info "Memcached disabled via SOGO_START_MEMCACHED=false"
    fi
}

# --- START SOGO ---
start_sogo() {
    log_info "Starting SOGo..."
    
    # Check if SOGo is already running
    if pgrep -x sogod >/dev/null 2>&1; then
        log_warn "SOGo is already running, skipping start"
        return
    fi
    
    # Start SOGo in the foreground or background based on configuration
    exec /usr/sbin/sogod &
    SOGO_PID=$!
    log_info "SOGo started with PID: ${SOGO_PID}"
}

# --- MAIN EXECUTION ---
main() {
    log_info "Starting SOGo 5 entrypoint..."
    
    # Validate environment
    validate_env
    
    # Setup configuration
    setup_config
    
    # Setup directories
    setup_directories
    
    # Start memcached (in background)
    start_memcached
    
    # Start SOGo (in foreground)
    start_sogo
    
    # Wait for both processes
    wait ${SOGO_PID} ${MEMCACHED_PID:-0} || true
    
    log_info "SOGo 5 has stopped"
}

# Run main function in background to allow signal handling
main &
MAIN_PID=$!

# Wait for main process or signals
wait ${MAIN_PID}
