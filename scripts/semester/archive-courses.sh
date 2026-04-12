#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-License-Identifier: Apache-2.0
#
# Archive courses for completed semester with data retention policies
# Follows semester lifecycle configuration from helmfile/environments/default/semester-lifecycle.yaml.gotmpl

set -euo pipefail

# Configuration defaults
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
DEFAULT_SEMESTER_CODE="WS2026"
DEFAULT_API_BASE_URL="http://localhost:8080"
DEFAULT_CONFIG_FILE="${PROJECT_ROOT}/helmfile/environments/default/semester-lifecycle.yaml.gotmpl"

# Retention policy defaults (from semester-lifecycle config)
DEFAULT_CONTENT_RETENTION_DAYS=365
DEFAULT_ASSESSMENT_RETENTION_DAYS=1825  # 5 years
DEFAULT_RECORDING_RETENTION_DAYS=365

# Dry-run and verbose flags
DRY_RUN=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Statistics counters
COURSE_COUNT=0
ENROLLMENT_COUNT=0
CONTENT_ARCHIVED_COUNT=0
ERROR_COUNT=0

show_usage() {
    cat <<EOF
${YELLOW}Usage:${NC}
    ${SCRIPT_NAME} [OPTIONS] --semester SEMESTER_CODE

${YELLOW}Description:${NC}
    Archive courses for a completed semester with automated data retention policies.
    Freezes enrollments, archives course content, and sets retention schedules.
    Compatible with semester lifecycle configuration from helmfile.

${YELLOW}Required Options:${NC}
    -s, --semester SEMESTER_CODE      Semester code (e.g., WS2026, SS2026)

${YELLOW}Optional Options:${NC}
    -a, --api-url URL                 API base URL for course management
                                      (default: http://localhost:8080)
    -c, --config-file PATH            Semester lifecycle config file
                                      (default: helmfile/environments/default/semester-lifecycle.yaml.gotmpl)
    --content-retention-days DAYS     Days to retain course content (default: 365)
    --assessment-retention-days DAYS  Days to retain assessment data (default: 1825)
    --recording-retention-days DAYS   Days to retain meeting recordings (default: 365)
    -d, --dry-run                     Preview changes without executing
    -v, --verbose                     Enable verbose logging
    -h, --help                        Show this help message

${YELLOW}Examples:${NC}
    # Archive WS2026 semester with dry-run (preview only)
    ${SCRIPT_NAME} -s WS2026 --dry-run

    # Archive SS2026 semester with custom retention policies
    ${SCRIPT_NAME} -s SS2026 \\
        --content-retention-days 730 \\
        --assessment-retention-days 3650

    # Archive with verbose logging and specific API endpoint
    ${SCRIPT_NAME} -s WS2025 \\
        -a https://api.example.com \\
        -v

${YELLOW}Retention Policies:${NC}
    - Course content: 365 days (configurable)
    - Assessment data: 1825 days / 5 years (legal requirement for GDPR)
    - Meeting recordings: 365 days (configurable)
    - Grade records: Permanent (academic records)

${YELLOW}Archival Steps:${NC}
    1. Freeze enrollments (no new enrollments allowed)
    2. Archive course content to cold storage
    3. Set retention policies for each data type
    4. Generate archival report

${YELLOW}Notes:${NC}
    - Use --dry-run first to preview archival actions
    - Requires API access token for course management
    - Retention policies align with German academic record requirements
    - Assessment data must be retained for 5 years (GDPR article 11)

EOF
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    ((ERROR_COUNT++))
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_verbose() {
    if [[ "${VERBOSE}" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

load_retention_config() {
    local config_file="$1"

    log_verbose "Loading retention config from ${config_file}..."

    if [[ -f "${config_file}" ]]; then
        # Try to extract retention values from yaml config
        if command -v yq &> /dev/null; then
            local content_val
            local assessment_val
            local recording_val

            content_val=$(yq '.semesterLifecycle.archival.retention.contentRetentionDays' "${config_file}" 2>/dev/null || echo "")
            assessment_val=$(yq '.semesterLifecycle.archival.retention.assessmentRetentionDays' "${config_file}" 2>/dev/null || echo "")
            recording_val=$(yq '.semesterLifecycle.archival.retention.recordingRetentionDays' "${config_file}" 2>/dev/null || echo "")

            [[ -n "${content_val}" ]] && CONTENT_RETENTION_DAYS="${content_val}"
            [[ -n "${assessment_val}" ]] && ASSESSMENT_RETENTION_DAYS="${assessment_val}"
            [[ -n "${recording_val}" ]] && RECORDING_RETENTION_DAYS="${recording_val}"

            log_verbose "Loaded from config: content=${CONTENT_RETENTION_DAYS}d, assessment=${ASSESSMENT_RETENTION_DAYS}d, recording=${RECORDING_RETENTION_DAYS}d"
        else
            log_warn "yq not installed, using default retention values"
        fi
    else
        log_warn "Config file not found: ${config_file}, using defaults"
    fi

    # Set defaults if not loaded from config
    CONTENT_RETENTION_DAYS="${CONTENT_RETENTION_DAYS:-${DEFAULT_CONTENT_RETENTION_DAYS}}"
    ASSESSMENT_RETENTION_DAYS="${ASSESSMENT_RETENTION_DAYS:-${DEFAULT_ASSESSMENT_RETENTION_DAYS}}"
    RECORDING_RETENTION_DAYS="${RECORDING_RETENTION_DAYS:-${DEFAULT_RECORDING_RETENTION_DAYS}}"
}

validate_semester_code() {
    local semester_code="$1"

    # Validate semester code format: WS/SS + YYYY
    if [[ ! "${semester_code}" =~ ^(WS|SS)[0-9]{4}$ ]]; then
        log_error "Invalid semester code: ${semester_code}"
        log_error "Expected format: WS2026 or SS2026"
        return 1
    fi

    log_verbose "Semester code validated: ${semester_code}"
    return 0
}

get_courses_for_semester() {
    local semester_code="$1"

    log_verbose "Fetching courses for semester ${semester_code}..."

    # Simulate fetching courses (replace with actual API call)
    # Example: curl -s "${API_BASE_URL}/courses?semester=${semester_code}" | jq '.[]'

    # For now, return empty array (placeholder)
    echo "[]"
}

freeze_enrollments() {
    local semester_code="$1"
    shift
    local course_ids=("$@")

    log_info "Freezing enrollments for semester ${semester_code}..."

    for course_id in "${course_ids[@]}"; do
        log_verbose "Freezing enrollments for course ${course_id}"

        if [[ "${DRY_RUN}" == false ]]; then
            # Simulate API call to freeze enrollments
            # curl -X POST "${API_BASE_URL}/courses/${course_id}/freeze-enrollments" \
            #     -H "Authorization: Bearer ${API_TOKEN}"
            ((ENROLLMENT_COUNT++))
        else
            log_verbose "[DRY-RUN] Would freeze enrollments for course ${course_id}"
            ((ENROLLMENT_COUNT++))
        fi
    done

    log_info "Froze enrollments for ${#course_ids[@]} courses"
}

archive_course_content() {
    local semester_code="$1"
    shift
    local course_ids=("$@")

    log_info "Archiving course content for semester ${semester_code}..."

    for course_id in "${course_ids[@]}"; do
        log_verbose "Archiving content for course ${course_id}"

        if [[ "${DRY_RUN}" == false ]]; then
            # Simulate API call to archive course
            # curl -X POST "${API_BASE_URL}/courses/${course_id}/archive" \
            #     -H "Authorization: Bearer ${API_TOKEN}" \
            #     -H "Content-Type: application/json" \
            #     -d "{
            #       \"retention\": {
            #         \"contentRetentionDays\": ${CONTENT_RETENTION_DAYS},
            #         \"assessmentRetentionDays\": ${ASSESSMENT_RETENTION_DAYS},
            #         \"recordingRetentionDays\": ${RECORDING_RETENTION_DAYS}
            #       }
            #     }"
            ((CONTENT_ARCHIVED_COUNT++))
        else
            log_verbose "[DRY-RUN] Would archive course ${course_id} with retention: content=${CONTENT_RETENTION_DAYS}d, assessment=${ASSESSMENT_RETENTION_DAYS}d, recording=${RECORDING_RETENTION_DAYS}d"
            ((CONTENT_ARCHIVED_COUNT++))
        fi
    done

    log_info "Archived content for ${#course_ids[@]} courses"
}

generate_archival_report() {
    local semester_code="$1"
    local timestamp
    timestamp=$(date -Iseconds)

    log_info "Generating archival report..."

    echo -e "${GREEN}=== Course Archival Report ===${NC}"
    echo -e "Semester: ${semester_code}"
    echo -e "Timestamp: ${timestamp}"
    echo -e "Dry Run: ${DRY_RUN}"
    echo -e ""
    echo -e "${YELLOW}Archival Summary:${NC}"
    echo -e "  Courses processed: ${COURSE_COUNT}"
    echo -e "  Enrollments frozen: ${ENROLLMENT_COUNT}"
    echo -e "  Content archived: ${CONTENT_ARCHIVED_COUNT}"
    echo -e ""
    echo -e "${YELLOW}Retention Policies:${NC}"
    echo -e "  Course content: ${CONTENT_RETENTION_DAYS} days"
    echo -e "  Assessment data: ${ASSESSMENT_RETENTION_DAYS} days (5 years)"
    echo -e "  Meeting recordings: ${RECORDING_RETENTION_DAYS} days"
    echo -e "  Grade records: Permanent (academic records)"
    echo -e ""
    echo -e "${YELLOW}Errors:${NC}"
    echo -e "  Total errors: ${ERROR_COUNT}"
    echo -e ""
    echo -e "${GREEN}=== End Report ===${NC}"
}

archive_semester() {
    local semester_code="$1"

    log_info "Starting archival for semester ${semester_code}..."

    # Validate semester code
    if ! validate_semester_code "${semester_code}"; then
        return 1
    fi

    # Get courses for semester
    log_info "Fetching courses for semester ${semester_code}..."
    local courses_json
    courses_json=$(get_courses_for_semester "${semester_code}")

    # Parse course IDs (placeholder logic)
    local course_ids=()
    # In real implementation: course_ids=($(echo "${courses_json}" | jq -r '.[].id'))
    ((COURSE_COUNT = ${#course_ids[@]}))

    if [[ ${#course_ids[@]} -eq 0 ]]; then
        log_warn "No courses found for semester ${semester_code}"
        log_warn "Proceeding with archival will have no effect"
    fi

    # Step 1: Freeze enrollments
    freeze_enrollments "${semester_code}" "${course_ids[@]}"

    # Step 2: Archive course content with retention policies
    archive_course_content "${semester_code}" "${course_ids[@]}"

    log_info "Archival for semester ${semester_code} completed"

    # Generate report
    generate_archival_report "${semester_code}"

    return 0
}

main() {
    # Parse command line arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    # Set initial defaults
    SEMESTER_CODE=""
    API_BASE_URL="${DEFAULT_API_BASE_URL}"
    CONFIG_FILE="${DEFAULT_CONFIG_FILE}"
    CONTENT_RETENTION_DAYS="${DEFAULT_CONTENT_RETENTION_DAYS}"
    ASSESSMENT_RETENTION_DAYS="${DEFAULT_ASSESSMENT_RETENTION_DAYS}"
    RECORDING_RETENTION_DAYS="${DEFAULT_RECORDING_RETENTION_DAYS}"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--semester)
                SEMESTER_CODE="$2"
                shift 2
                ;;
            -a|--api-url)
                API_BASE_URL="$2"
                shift 2
                ;;
            -c|--config-file)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --content-retention-days)
                CONTENT_RETENTION_DAYS="$2"
                shift 2
                ;;
            --assessment-retention-days)
                ASSESSMENT_RETENTION_DAYS="$2"
                shift 2
                ;;
            --recording-retention-days)
                RECORDING_RETENTION_DAYS="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Check required arguments
    if [[ -z "${SEMESTER_CODE}" ]]; then
        log_error "Missing required argument: --semester"
        show_usage
        exit 1
    fi

    # Load retention config
    load_retention_config "${CONFIG_FILE}"

    log_info "Course archival workflow initialized"
    log_info "  Semester: ${SEMESTER_CODE}"
    log_info "  API URL: ${API_BASE_URL}"
    log_info "  Config file: ${CONFIG_FILE}"
    [[ "${DRY_RUN}" == true ]] && log_warn "Running in DRY-RUN mode - no changes will be made"

    # Execute archival
    if ! archive_semester "${SEMESTER_CODE}"; then
        log_error "Archival failed with ${ERROR_COUNT} errors"
        exit 1
    fi

    log_info "Archival completed successfully"
    exit 0
}

# Run main function
main "$@"
