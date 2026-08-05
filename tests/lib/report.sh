# Report formatting functions for test framework

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS="✓"
FAIL="✗"
WARN="⚠"

# Print test section header
print_section() {
    local title="$1"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$title${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

# Print test result
print_result() {
    local status="$1"
    local message="$2"
    
    case $status in
        PASS)
            echo -e "${GREEN}${PASS} $message${NC}"
            ;;
        FAIL)
            echo -e "${RED}${FAIL} $message${NC}"
            ;;
        WARN)
            echo -e "${YELLOW}${WARN} $message${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Format table
print_table() {
    local header="$1"
    local data="$2"
    
    echo ""
    echo -e "${BLUE}$header${NC}"
    echo "$data"
}

# Format JSON output
json_output() {
    local test_name="$1"
    local test_type="$2"
    local status="$3"
    local message="$4"
    local details="${5:-{}}"
    
    cat <<EOF
{
  "test": "$test_name",
  "type": "$test_type",
  "status": "$status",
  "message": "$message",
  "details": $details,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Exit with error
error_exit() {
    local message="$1"
    echo -e "${RED}ERROR: $message${NC}" >&2
    exit 1
}

# Check command result
check_result() {
    local result="$1"
    local message="$2"
    local severity="${3:-error}"
    
    if [ $result -ne 0 ]; then
        if [ "$severity" = "error" ]; then
            print_result FAIL "$message"
            return 1
        elif [ "$severity" = "warning" ]; then
            print_result WARN "$message"
            return 0
        fi
    else
        print_result PASS "$message"
        return 0
    fi
}

# Summarize test results
summarize_results() {
    local total="$1"
    local passed="$2"
    local failed="$3"
    local warnings="$4"
    local test_name="$5"
    
    local percent_passed=0
    if [ $total -gt 0 ]; then
        percent_passed=$(( (passed * 100) / total ))
    fi
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$test_name Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "Total:   $total"
    echo -e "${GREEN}Passed:  $passed${NC}"
    echo -e "${RED}Failed:  $failed${NC}"
    echo -e "${YELLOW}Warnings: $warnings${NC}"
    echo -e "Success: ${percent_passed}%"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ $failed -gt 0 ]; then
        return 1
    fi
    return 0
}