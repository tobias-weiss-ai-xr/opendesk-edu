#!/bin/bash
# Ralph Loop Notification Script
# Sends notifications about Ralph loop results via various channels
# Usage: bash notify.sh

set -e

REPORTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/reports"
LOG_DIR="/var/log/ralph"
NOTIFICATION_LOG="$LOG_DIR/notifications.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

log() {
    local timestamp=$(date -Iseconds)
    echo "[$timestamp] $1" | tee -a "$NOTIFICATION_LOG" 2>/dev/null || echo "[$timestamp] $1"
}

log "Starting notification processing"

if [ ! -d "$REPORTS_DIR" ]; then
    log "ERROR: Reports directory not found: $REPORTS_DIR"
    exit 1
fi

LATEST_REPORT=$(ls -t "$REPORTS_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
    log "No reports found"
    exit 0
fi

log "Latest report: $LATEST_REPORT"

FAILED_COUNT=$(grep -c "^### ❌" "$LATEST_REPORT" 2>/dev/null || echo "0")
TOTAL_TASKS=$(grep -c "^### " "$LATEST_REPORT" 2>/dev/null || echo "0")

log "Results: $FAILED_COUNT failed out of $TOTAL_TASKS tasks"

if [ "$FAILED_COUNT" -gt 0 ]; then
    log "FAILURES DETECTED - Notifications would be sent here"
    
    cat > /tmp/ralph-alert.txt <<EOF
Ralph Loop Alert
=================
Report: $LATEST_REPORT
Failed tasks: $FAILED_COUNT
Total tasks: $TOTAL_TASKS

Latest failures:
EOF
    
    grep "^### ❌" "$LATEST_REPORT" | head -10 >> /tmp/ralph-alert.txt
    
    log "Alert file created: /tmp/ralph-alert.txt"
    
    if [ -n "${MATRIX_WEBHOOK_URL:-}" ]; then
        log "Matrix webhook configured (but not sending in test mode)"
    fi
    
    if [ -n "${EMAIL_SMTP_HOST:-}" ]; then
        log "Email configured (but not sending in test mode)"
    fi
    
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        log "Slack webhook configured (but not sending in test mode)"
    fi
else
    log "All checks passed - no alerts needed"
fi

log "Notification processing complete"
exit 0
