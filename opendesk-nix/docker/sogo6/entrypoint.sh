#!/bin/bash
# SOGo 6 Entrypoint Script for openDesk
# Handles multi-process setup (SOGo + Memcached), signal handling, and graceful shutdown
# Optimized for SOGo 6 with improved caching and performance
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# ============================================
# LOGGING FUNCTIONS
# ============================================
log_info() {
    echo "[INFO] [$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_warn() {
    echo "[WARN] [$(date +'%Y-%m-%d %H:%M:%S')] $1" >&2
}

log_error() {
    echo "[ERROR] [$(date +'%Y-%m-%d %H:%M:%S')] $1" >&2
}

# ============================================
# SIGNAL HANDLING - Graceful shutdown
# ============================================
SOGO_PID=""
MEMCACHED_PID=""

handle_signal() {
    local signal="$1"
    log_info "Received ${signal}, initiating graceful shutdown..."
    
    # Send signal to SOGo
    if [ -n "$SOGO_PID" ] && kill -0 "$SOGO_PID" 2>/dev/null; then
        kill -"${signal}" "$SOGO_PID" 2>/dev/null || true
    fi
    
    # Send signal to Memcached
    if [ -n "$MEMCACHED_PID" ] && kill -0 "$MEMCACHED_PID" 2>/dev/null; then
        kill -"${signal}" "$MEMCACHED_PID" 2>/dev/null || true
    fi
    
    # Wait for processes to terminate
    if [ -n "$SOGO_PID" ]; then
        wait "$SOGO_PID" 2>/dev/null || true
    fi
    if [ -n "$MEMCACHED_PID" ]; then
        wait "$MEMCACHED_PID" 2>/dev/null || true
    fi
    
    log_info "SOGo 6 and dependencies have been stopped gracefully"
    exit 0
}

trap 'handle_signal TERM' TERM
trap 'handle_signal INT' INT
trap 'handle_signal QUIT' QUIT
trap 'handle_signal HUP' HUP

# ============================================
# ENVIRONMENT VALIDATION
# ============================================
validate_environment() {
    log_info "Validating environment..."
    
    # Check required environment variables
    if [ -z "${SOGO_LDAP_BIND_PASSWORD:-}" ] && [ ! -f /etc/sogo/ldap-password ]; then
        log_warn "SOGO_LDAP_BIND_PASSWORD not set and no ldap-password file found"
    fi
    
    # Set defaults for all configurable parameters
    : "${SOGO_VERSION:=6.0.0}"
    : "${SOGO_USER_SOURCES:=}"
    : "${SOGO_PROFILE_URL:=postgresql://sogo:sogo@postgresql.opendesk.svc:5432/sogo}"
    : "${SOGO_FOLDER_INFO_URL:=postgresql://sogo:sogo@postgresql.opendesk.svc:5432/sogo}"
    : "${SOGO_SESSIONS_URL:=postgresql://sogo:sogo@postgresql.opendesk.svc:5432/sogo}"
    : "${SOGO_EMAIL_DOMAINS:=(\"opendesk.org\")}"
    : "${SOGO_IMAP_SERVER:=imap.opendesk.svc}"
    : "${SOGO_SMTP_SERVER:=smtp.opendesk.svc}"
    : "${SOGO_SIEVE_SERVER:=sieve.opendesk.svc}"
    : "${SOGO_MEMCACHED_HOST:=memcached.opendesk.svc}"
    : "${SOGO_MEMCACHED_PORT:=11211}"
    : "${SOGO_TIMEZONE:=Europe/Berlin}"
    : "${SOGO_LANGUAGE:=German}"
    : "${SOGO_MAX_MESSAGE_SIZE:=200}"
    : "${SOGO_WORKERS:=15}"
    : "${SOGO_MAX_THREADS:=200}"
    : "${SOGO_START_MEMCACHED:=true}"
    : "${SOGO_DEBUG:=NO}"
    
    log_info "Environment validation complete"
}

# ============================================
# DIRECTORY SETUP
# ============================================
setup_directories() {
    log_info "Setting up directories..."
    
    # Ensure all required directories exist
    mkdir -p /var/lib/sogo /var/log/sogo /run/sogo /tmp
    
    # Set proper permissions
    chown -R sogo:sogo /var/lib/sogo /var/log/sogo /run/sogo
    chmod -R 750 /var/lib/sogo /var/log/sogo
    chmod 755 /run/sogo /tmp
    
    # Ensure SOGo specific directories exist
    mkdir -p /usr/lib/SOGo /usr/lib-GNUstep
    chown -R sogo:sogo /usr/lib/SOGo /usr/lib-GNUstep
    
    log_info "Directories setup complete"
}

# ============================================
# CONFIGURATION SETUP
# ============================================
setup_configuration() {
    log_info "Setting up SOGo 6 configuration..."
    
    # 1. Create default memcached configuration
    if [ ! -f /etc/memcached.conf ]; then
        cat > /etc/memcached.conf << 'EOF'
# Memcached for SOGo 6
-p 11211
-l 127.0.0.1
-m 512
-c 2048
-u sogo
-t 4
-d
-k
-moden
EOF
        chmod 644 /etc/memcached.conf
    fi
    
    # 2. Create LDAP password file if environment variable is set
    if [ -n "${SOGO_LDAP_BIND_PASSWORD:-}" ] && [ ! -f /etc/sogo/ldap-password ]; then
        echo "${SOGO_LDAP_BIND_PASSWORD}" > /etc/sogo/ldap-password
        chmod 600 /etc/sogo/ldap-password
        chown sogo:sogo /etc/sogo/ldap-password
    fi
    
    # 3. Apply environment variable overrides to sogo.conf
    #    We use sed to replace placeholders with actual values
    
    # Profile URL
    if [ -n "${SOGO_PROFILE_URL:-}" ]; then
        sed -i "s|SOGoProfileURL.*|SOGoProfileURL = \"${SOGO_PROFILE_URL}\";|" /etc/sogo/sogo.conf
    fi
    
    # Folder Info URL
    if [ -n "${SOGO_FOLDER_INFO_URL:-}" ]; then
        sed -i "s|OCSFolderInfoURL.*|OCSFolderInfoURL = \"${SOGO_FOLDER_INFO_URL}\";|" /etc/sogo/sogo.conf
    fi
    
    # Sessions URL
    if [ -n "${SOGO_SESSIONS_URL:-}" ]; then
        sed -i "s|OCSSessionsFolderURL.*|OCSSessionsFolderURL = \"${SOGO_SESSIONS_URL}\";|" /etc/sogo/sogo.conf
    fi
    
    # Email domains
    if [ -n "${SOGO_EMAIL_DOMAINS:-}" ]; then
        sed -i "s|OCSEMailDomains.*|OCSEMailDomains = ${SOGO_EMAIL_DOMAINS};|" /etc/sogo/sogo.conf
    fi
    
    # IMAP Server
    if [ -n "${SOGO_IMAP_SERVER:-}" ]; then
        sed -i "s|SOGoIMAPServer.*|SOGoIMAPServer = \"${SOGO_IMAP_SERVER}\";|" /etc/sogo/sogo.conf
    fi
    
    # SMTP Server
    if [ -n "${SOGO_SMTP_SERVER:-}" ]; then
        sed -i "s|SOGoSMTPServer.*|SOGoSMTPServer = \"${SOGO_SMTP_SERVER}\";|" /etc/sogo/sogo.conf
    fi
    
    # Sieve Server
    if [ -n "${SOGO_SIEVE_SERVER:-}" ]; then
        sed -i "s|SOGoSieveServer.*|SOGoSieveServer = \"${SOGO_SIEVE_SERVER}\";|" /etc/sogo/sogo.conf
    fi
    
    # Memcached Host
    if [ -n "${SOGO_MEMCACHED_HOST:-}" ]; then
        sed -i "s|SOGOMemcachedHost.*|SOGOMemcachedHost = \"${SOGO_MEMCACHED_HOST}\";|" /etc/sogo/sogo.conf
    fi
    
    # Memcached Port
    if [ -n "${SOGO_MEMCACHED_PORT:-}" ]; then
        sed -i "s|SOGOMemcachedPort.*|SOGOMemcachedPort = \"${SOGO_MEMCACHED_PORT}\";|" /etc/sogo/sogo.conf
    fi
    
    # Maximum Message Size
    if [ -n "${SOGO_MAX_MESSAGE_SIZE:-}" ]; then
        sed -i "s|SOGoMaximumMessageSize.*|SOGoMaximumMessageSize = ${SOGO_MAX_MESSAGE_SIZE};|" /etc/sogo/sogo.conf
    fi
    
    # Workers Count
    if [ -n "${SOGO_WORKERS:-}" ]; then
        sed -i "s|WOWorkersCount.*|WOWorkersCount = ${SOGO_WORKERS};|" /etc/sogo/sogo.conf
    fi
    
    # Max Threads Per Worker
    if [ -n "${SOGO_MAX_THREADS:-}" ]; then
        sed -i "s|WOMaxThreadsPerWorker.*|WOMaxThreadsPerWorker = ${SOGO_MAX_THREADS};|" /etc/sogo/sogo.conf
    fi
    
    # Debug Settings
    if [ "${SOGO_DEBUG:-NO}" = "YES" ]; then
        sed -i "s/SOGoDebugRequests = NO/SOGoDebugRequests = YES/" /etc/sogo/sogo.conf
        sed -i "s/SOGoDebugSQLQueries = NO/SOGoDebugSQLQueries = YES/" /etc/sogo/sogo.conf
    fi
    
    # Timezone
    if [ -n "${SOGO_TIMEZONE:-}" ]; then
        sed -i "s|SOGoTimeZone.*|SOGoTimeZone = \"${SOGO_TIMEZONE}\";|" /etc/sogo/sogo.conf
    fi
    
    # Language
    if [ -n "${SOGO_LANGUAGE:-}" ]; then
        sed -i "s|SOGoLanguage.*|SOGoLanguage = \"${SOGO_LANGUAGE}\";|" /etc/sogo/sogo.conf
    fi
    
    log_info "SOGo 6 configuration setup complete"
}

# ============================================
# START MEMCACHED
# ============================================
start_memcached() {
    log_info "Checking memcached configuration..."
    
    # Check if we should start memcached
    if [ "${SOGO_START_MEMCACHED:-true}" != "false" ]; then
        log_info "Starting memcached for SOGo 6..."
        /usr/bin/memcached -u sogo -d -p 11211 -m 512 -c 2048 -l 127.0.0.1 -t 4 -d -k -moden &
        MEMCACHED_PID=$!
        log_info "Memcached started with PID: ${MEMCACHED_PID}"
        
        # Wait for memcached to start
        sleep 2
        if pgrep -x memcached >/dev/null 2>&1; then
            log_info "Memcached is running successfully"
        else
            log_error "Memcached failed to start!"
            MEMCACHED_PID=""
        fi
    else
        log_info "Memcached disabled via SOGO_START_MEMCACHED=false"
    fi
}

# ============================================
# START SOGO 6
# ============================================
start_sogo() {
    log_info "Starting SOGo 6..."
    
    # Check if SOGo is already running
    if pgrep -x sogod >/dev/null 2>&1; then
        log_warn "SOGo is already running, skipping start"
        return
    fi
    
    # Start SOGo in the background
    # Note: We're running in background to allow for multi-process management
    exec /usr/sbin/sogod &
    SOGO_PID=$!
    log_info "SOGo 6 started with PID: ${SOGO_PID}"
    
    # Wait for SOGo to initialize
    for i in $(seq 1 30); do
        if curl -sSf http://localhost:20000/SOGo >/dev/null 2>&1; then
            log_info "SOGo 6 is now accepting connections"
            break
        fi
        sleep 2
        if [ $i -eq 30 ]; then
            log_warn "SOGo 6 took more than 60 seconds to start"
        fi
    done
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    log_info "========================================"
    log_info "Starting SOGo 6 v${SOGO_VERSION:-6.0.0} for openDesk"
    log_info "========================================"
    
    # Validate environment
    validate_environment
    
    # Setup directories
    setup_directories
    
    # Setup configuration (before starting services)
    setup_configuration
    
    # Start memcached first (SOGo 6 benefits from caching)
    start_memcached
    
    # Start SOGo 6
    start_sogo
    
    # Main process loop
    log_info "SOGo 6 and dependencies are running"
    log_info "Press Ctrl+C to gracefully stop all services"
    
    # Wait for signals or child processes
    while true; do
        # Check if SOGo is still running
        if [ -n "$SOGO_PID" ] && ! kill -0 "$SOGO_PID" 2>/dev/null; then
            log_warn "SOGo 6 process (PID: ${SOGO_PID}) has terminated unexpectedly"
            SOGO_PID=""
        fi
        
        # Check if Memcached is still running
        if [ -n "$MEMCACHED_PID" ] && ! kill -0 "$MEMCACHED_PID" 2>/dev/null; then
            log_warn "Memcached process (PID: ${MEMCACHED_PID}) has terminated unexpectedly"
            MEMCACHED_PID=""
        fi
        
        # If both processes are dead, exit
        if [ -z "$SOGO_PID" ] && [ -z "$MEMCACHED_PID" ]; then
            log_info "All processes have terminated"
            exit 0
        fi
        
        # Sleep for a bit
        sleep 5
    done
}

# Run main function
main
