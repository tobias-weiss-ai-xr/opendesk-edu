# HTTP helper functions for test framework

# Common HTTP status codes
HTTP_OK=200
HTTP_REDIRECT_PERMANENT=301
HTTP_REDIRECT_TEMPORARY=302
HTTP_UNAUTHORIZED=401
HTTP_FORBIDDEN=403
HTTP_NOT_FOUND=404
HTTP_SERVER_ERROR=500

# Default timeout
HTTP_TIMEOUT="${HTTP_TIMEOUT:-10}"

# Check SSL certificate expiry
check_ssl_expiry() {
    local host="$1"
    local expiry_days
    
    expiry_days=$(openssl s_client -connect "$host:443" -servername "$host" </dev/null 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | cut -d= -f2 \
        | xargs -I {} date -d {} +%s)
    
    if [ -z "$expiry_days" ]; then
        echo "ERROR: Cannot get SSL expiry for $host"
        return 1
    fi
    
    local now
    now=$(date +%s)
    local days_until_expiry=$(( (expiry_days - now) / 86400 ))
    
    echo "$days_until_expiry"
}

# Make HTTP request with redirect following
http_request() {
    local url="$1"
    local method="${2:-GET}"
    local headers=""
    local follow_redirects="${FOLLOW_REDIRECTS:-true}"
    local max_redirects=5
    
    local curl_opts=(
        -sSf
        --max-time "$HTTP_TIMEOUT"
        -w "\n%{http_code}"
        -o /tmp/http_response_body_$$
    )
    
    if [ "$follow_redirects" = "true" ]; then
        curl_opts+=( -L )
        curl_opts+=( --max-redirs "$max_redirects" )
    else
        curl_opts+=( --max-redirs 0 )
    fi
    
    # Add headers if provided
    if [ -n "$headers" ]; then
        curl_opts+=( -H "$headers" )
    fi
    
    local response
    response=$(curl "${curl_opts[@]}" -X "$method" "$url" 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -1)
    local response_body=$(cat /tmp/http_response_body_$$ 2>/dev/null)
    rm -f /tmp/http_response_body_$$
    
    echo "$response_body"
    return "$http_code"
}

# Get HTTP response code only
get_http_code() {
    local url="$1"
    local method="${2:-GET}"
    local insecure_flag=""
    if [ "${INSECURE_SSL:-true}" = "true" ]; then
        insecure_flag="-k"
    fi
    
    curl $insecure_flag -sS -o /dev/null -w "%{http_code}" --max-time "$HTTP_TIMEOUT" -X "$method" "$url" 2>/dev/null
}

# Check if HTTP code is acceptable
is_http_code_acceptable() {
    local code="$1"
    local acceptable_codes="${ACCEPTABLE_HTTP_CODES:-200 301 302 401 403}"
    
    for acceptable in $acceptable_codes; do
        if [ "$code" = "$acceptable" ]; then
            return 0
        fi
    done
    return 1
}

# Retry HTTP request
http_retry() {
    local url="$1"
    local method="${2:-GET}"
    local max_attempts="${HTTP_RETRY_ATTEMPTS:-2}"
    local attempt=1
    local response_code
    local response_body
    
    while [ $attempt -le $max_attempts ]; do
        response_body=$(http_request "$url" "$method")
        response_code=$?
        
        if is_http_code_acceptable "$response_code"; then
            echo "$response_body"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            sleep 1
        fi
        
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: HTTP request failed after $max_attempts attempts: $url (code: $response_code)"
    return 1
}

# Check OIDC well-known configuration
check_oidc_well_known() {
    local host="$1"
    local realm="${2:-opendesk}"
    
    local url="https://$host/realms/$realm/.well-known/openid-configuration"
    
    local response
    response=$(http_retry "$url")
    
    if echo "$response" | grep -q '"issuer"' && echo "$response" | grep -q '"authorization_endpoint"'; then
        echo "$response"
        return 0
    fi
    
    return 1
}

# Check SAML metadata
check_saml_metadata() {
    local url="$1"
    
    local response
    response=$(http_retry "$url")
    
    if echo "$response" | grep -q '<EntityDescriptor' && echo "$response" | grep -q 'entityID='; then
        echo "$response"
        return 0
    fi
    
    return 1
}

# Extract redirect URL from HTTP response
get_redirect_url() {
    local url="$1"
    
    local output
    output=$(curl -sSf -I --max-time "$HTTP_TIMEOUT" --max-redirs 0 "$url" 2>/dev/null)
    
    echo "$output" | grep -i '^Location:' | cut -d' ' -f2- | tr -d '\r'
}

# Check TCP port connectivity
check_tcp_port() {
    local host="$1"
    local port="$2"
    local timeout="${TCP_TIMEOUT:-3}"
    
    timeout "$timeout" bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null
}