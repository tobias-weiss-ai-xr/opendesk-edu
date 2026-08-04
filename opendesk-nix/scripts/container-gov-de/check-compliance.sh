#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 container.gov.de Contributors
# container.gov.de Compliance Checker
# Check BG-1 through BG-8 compliance for any service
# Usage: ./check-compliance.sh [SERVICE] [--all] [--json] [--html]

set -euo pipefail

# Configuration
NIX_FILE="templates/container-gov-de/default.nix"
REPORT_DIR="./reports"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [SERVICE]

Check container.gov.de compliance for a service

Options:
  SERVICE        Service name (e.g., nginx, mariadb, postgresql)
  --all          Check all 75 services
  --json         Output JSON report
  --html         Output HTML report
  --quiet        Suppress detailed output
  --help         Show this help message

Examples:
  $0 nginx                    # Check nginx compliance
  $0 --all                     # Check all services
  $0 nginx --json             # Output JSON report
  $0 --all --html             # Generate HTML report for all services

container.gov.de Requirements:
  BG-1: Trusted Base Images
  BG-2: Non-Root User
  BG-3: Minimal Rights
  BG-4: Protection of Sensitive Data
  BG-5: Regular Updates
  BG-6: SBOM Generation
  BG-7: Image Signing
  BG-8: Vulnerability Scanning
EOF
}

# Get all services from docker/services directory
get_services() {
    cd "$PROJECT_ROOT"
    if [ -d "docker/services" ]; then
        find docker/services -maxdepth 1 -type d ! -name "services" ! -name "*.nix" ! -name "README*" ! -name ".*" | sed 's|docker/services/||' | tr '\n' ' '
    else
        echo "nginx mariadb postgresql redis traefik keycloak"
    fi
}

# Check a single service
check_service() {
    local service="$1"
    local quiet="$2"
    
    cd "$PROJECT_ROOT"
    
    if [ ! -z "$quiet" ]; then
        echo "Checking ${service}..."
    fi
    
    # Build the compliance check derivation
    local build_output
    if build_output=$(nix build -f "$NIX_FILE" -A "complianceCheck" --argstr "service" "$service" 2>&1); then
        local result_file=$(echo "$build_output" | grep -oE '/nix/store/[^ ]+')
        
        if [ -f "$result_file" ]; then
            # Parse the result (it's a JSON file)
            local compliance_level=$(jq -r '.complianceLevel' "$result_file" 2>/dev/null || echo "UNKNOWN")
            local passed=$(jq -r '.passed' "$result_file" 2>/dev/null || echo "0")
            local total=$(jq -r '.total' "$result_file" 2>/dev/null || echo "0")
            local percentage=$(jq -r '.passedPercentage' "$result_file" 2>/dev/null || echo "0")
            
            if [ "$compliance_level" = "FULLY COMPLIANT" ]; then
                echo -e "${GREEN}✓ ${service}: FULLY COMPLIANT (${passed}/${total} checks, ${percentage}%)${NC}"
            elif [ "$compliance_level" = "HIGH COMPLIANCE" ]; then
                echo -e "${YELLOW}⚠ ${service}: HIGH COMPLIANCE (${passed}/${total} checks, ${percentage}%)${NC}"
            else
                echo -e "${RED}✗ ${service}: ${compliance_level} (${passed}/${total} checks, ${percentage}%)${NC}"
            fi
            
            # Output details if not quiet
            if [ -z "$quiet" ]; then
                jq '.' "$result_file" 2>/dev/null || true
                echo ""
            fi
            
            # Clean up
            rm -f "$result_file"
            
            return 0
        fi
    else
        echo -e "${RED}✗ ${service}: Build failed${NC}"
        if [ -z "$quiet" ]; then
            echo "$build_output"
        fi
        return 1
    fi
}

# Check all services
check_all_services() {
    local services=($(get_services))
    local json_output="[]"
    local total_services=${#services[@]}
    local compliant_count=0
    local failed_count=0
    
    echo -e "${BLUE}Checking container.gov.de compliance for ${total_services} services...${NC}"
    echo "============================================"
    
    for service in "${services[@]}"; do
        if [ -z "$service" ]; then
            continue
        fi
        
        local result
        if result=$(check_service "$service" "quiet" 2>&1); then
            json_output=$(echo "$json_output" | jq --arg s "$service" --arg r "$result" '. + [$s + " - " + $r]')
            
            # Count compliant services
            if echo "$result" | grep -q "FULLY COMPLIANT"; then
                ((compliant_count++))
            elif echo "$result" | grep -q "✗"; then
                ((failed_count++))
            fi
            
            echo "$result"
        else
            echo -e "${RED}✗ ${service}: Error${NC}"
            json_output=$(echo "$json_output" | jq --arg s "$service" --arg r "Error" '. + [$s + " - " + $r]')
            ((failed_count++))
        fi
    done
    
    echo "============================================"
    echo -e "${BLUE}Summary:${NC}"
    echo -e "  Total services:  ${total_services}"
    echo -e "  Fully compliant: ${GREEN}${compliant_count}${NC}"
    echo -e "  Failed:           ${RED}${failed_count}${NC}"
    echo -e "  Compliance rate: ${GREEN}$((compliant_count * 100 / total_services))%${NC}"
    
    if [ "$1" = "--json" ]; then
        echo "$json_output" | jq '.'
    fi
    
    if [ "$1" = "--html" ]; then
        generate_html_report "$json_output"
    fi
}

# Generate HTML report
generate_html_report() {
    local json_data="$1"
    local output_file="$REPORT_DIR/compliance-report-$(date +%Y%m%d-%H%M%S).html"
    
    mkdir -p "$REPORT_DIR"
    
    cat > "$output_file" << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>container.gov.de Compliance Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        h1 { color: #004488; text-align: center; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .summary { background: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .service { padding: 15px; margin: 10px 0; border-radius: 4px; border-left: 4px solid #007bff; }
        .service.compliant { border-left-color: #28a745; }
        .service.non-compliant { border-left-color: #dc3545; }
        .service.partial { border-left-color: #ffc107; }
        .compliance-badge { padding: 5px 15px; border-radius: 20px; font-weight: bold; font-size: 0.9em; }
        .badge-compliant { background: #28a745; color: white; }
        .badge-non-compliant { background: #dc3545; color: white; }
        .badge-partial { background: #ffc107; color: black; }
        table { width: 100%; margin: 10px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #004488; color: white; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666; }
        .pass { color: #28a745; }
        .fail { color: #dc3545; }
    </style>
</head>
<body>
    <div class="container">
        <h1>container.gov.de Compliance Report</h1>
        <p>Generated: DESCRIPTION</p>
        <p>Standard: <a href="https://container.gov.de">container.gov.de v1.0</a> (BSI)</p>
        
        <div class="summary">
            <h2>Summary</h2>
            <p><strong>Total Services:</strong> <span id="total">0</span></p>
            <p><strong>Fully Compliant:</strong> <span id="compliant">0</span> <span class="badge-compliant">✓</span></p>
            <p><strong>Partial Compliance:</strong> <span id="partial">0</span> <span class="badge-partial">⚠</span></p>
            <p><strong>Non-Compliant:</strong> <span id="non-compliant">0</span> <span class="badge-non-compliant">✗</span></p>
        </div>
        
        <h2>Details</h2>
        <div id="services-list"></div>
        
        <div class="footer">
            <p><small>Generated by <a href="https://github.com/opendesk-edu/opendesk-nix">openDesk Nix</a> | 
            <a href="https://container.gov.de">container.gov.de</a> | 
            <a href="https://www.bsi.bund.de">BSI</a></small></p>
        </div>
    </div>
    
    <script>
        const data = DATA;
        
        // Parse data
        let total = 0;
        let compliant = 0;
        let partial = 0;
        let nonCompliant = 0;
        
        const services = data.map(item => {
            const [service, ...rest] = item.split(/ - /);
            const status = rest.join(' - ');
            total++;
            
            if (status.includes('FULLY COMPLIANT')) {
                compliant++;
                return { service, status, type: 'compliant' };
            } else if (status.includes('HIGH COMPLIANCE') || status.includes('MEDIUM COMPLIANCE')) {
                partial++;
                return { service, status, type: 'partial' };
            } else {
                nonCompliant++;
                return { service, status, type: 'non-compliant' };
            }
        });
        
        // Update summary
        document.getElementById('total').textContent = total;
        document.getElementById('compliant').textContent = compliant;
        document.getElementById('partial').textContent = partial;
        document.getElementById('non-compliant').textContent = nonCompliant;
        
        // Generate services list
        const listDiv = document.getElementById('services-list');
        services.forEach(svc => {
            const div = document.createElement('div');
            div.className = `service ${svc.type}`;
            
            let badge;
            if (svc.type === 'compliant') {
                badge = '<span class="compliance-badge badge-compliant">FULLY COMPLIANT</span>';
            } else if (svc.type === 'partial') {
                badge = '<span class="compliance-badge badge-partial">PARTIAL COMPLIANCE</span>';
            } else {
                badge = '<span class="compliance-badge badge-non-compliant">NON-COMPLIANT</span>';
            }
            
            div.innerHTML = `
                <h3>${svc.service} ${badge}</h3>
                <p class="${svc.type === 'compliant' ? 'pass' : svc.type === 'non-compliant' ? 'fail' : ''}">
                    ${svc.status}
                </p>
            `;
            listDiv.appendChild(div);
        });
    </script>
</body>
</html>
HTML
    
    # Replace placeholders
    sed -i "s|DESCRIPTION|$(date)|" "$output_file"
    sed -i "s|DATA|$(echo "$json_data" | jq -c .)|" "$output_file"
    
    echo -e "${GREEN}HTML report generated: $output_file${NC}"
}

# Main function
main() {
    local service=""
    local do_all=false
    local output_json=false
    local output_html=false
    local quiet=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                do_all=true
                shift
                ;;
            --json)
                output_json=true
                shift
                ;;
            --html)
                output_html=true
                shift
                ;;
            --quiet)
                quiet=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                exit 1
                ;;
            *)
                if [ -z "$service" ]; then
                    service="$1"
                else
                    echo -e "${RED}Multiple services specified: $service and $1${NC}"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    cd "$PROJECT_ROOT"
    
    # Check if we're in a Nix flake directory
    if [ ! -f "flake.nix" ]; then
        echo -e "${RED}Error: Not in a Nix flake directory${NC}"
        exit 1
    fi
    
    if [ "$do_all" = true ]; then
        # Check all services
        local output_format=""
        if [ "$output_json" = true ]; then
            output_format="--json"
        elif [ "$output_html" = true ]; then
            output_format="--html"
        fi
        check_all_services "$output_format"
    elif [ -n "$service" ]; then
        # Check single service
        if [ "$output_json" = true ]; then
            echo "{\"service\": \"$service\", \"result\": "
            check_service "$service" "quiet"
            echo "}"
        elif [ "$output_html" = true ]; then
            local json_result=$(check_service "$service" "quiet" 2>&1 | jq -c . || echo "{}")
            generate_html_report "[\"${service} - ${json_result}\"]"
        else
            check_service "$service" ""
        fi
    else
        usage
        exit 1
    fi
}

main "$@"
