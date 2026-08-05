#!/bin/bash
# DNS A records needed for opendesk-edu services
# Run on the HRZ DNS server to add these records
# All point to the ingress IP 192.168.3.201 (haproxy ingress controller)
#
# Already has valid external A records:
#   bookstack, projects, moodle, etherpad, excalidraw, planka,
#   sogo, ssp, helpdesk, lms, whiteboard, pad
#
# M
INGRESS_IP="192.168.3.201"

add_record() {
    local subdomain="$1"
    echo "${subdomain}.opendesk.hrz.uni-marburg.de. IN A ${INGRESS_IP}"
}

cat << EOF
; opendesk-edu DNS records
; Add these to the hrz.uni-marburg.de zone
;
; All point to ingress controller at ${INGRESS_IP}
; Last reviewed: 2026-06-03
;

; Education services missing external A records
$(add_record n8n)       ; n8n workflow automation
$(add_record code)      ; VS Code Server
$(add_record collab)    ; Collaboration dashboard
$(add_record draw)      ; Draw.io diagrams
$(add_record jupyter)   ; JupyterHub notebooks
$(add_record limesurvey); LimeSurvey
$(add_record typo3)     ; TYPO3 CMS
$(add_record zammad)    ; Zammad helpdesk
$(add_record r)         ; RStudio
$(add_record slides)    ; Slidev presentations
$(add_record term)      ; Terminal/ssh web client
$(add_record ai)        ; Open WebUI / AI chat
EOF
