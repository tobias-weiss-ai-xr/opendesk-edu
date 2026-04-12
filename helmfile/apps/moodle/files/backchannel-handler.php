<?php
// SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
// SPDX-License-Identifier: Apache-2.0
/**
 * SAML Backchannel Logout Handler for Moodle
 *
 * This handler receives SAML 2.0 LogoutRequest messages from Keycloak
 * and terminates the corresponding Moodle session.
 *
 * Endpoint: /Shibboleth.sso/Logout
 * Binding: SOAP or HTTP-POST
 */

declare(strict_types=1);

// Prevent direct access from browser (only allow server-to-server)
if (php_sapi_name() !== 'cli' && isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'GET') {
    // GET requests should be handled by mod_shib for frontchannel logout
    // This handler only processes backchannel POST requests
    http_response_code(405);
    header('Allow: POST');
    echo json_encode(['error' => 'Method Not Allowed', 'message' => 'Use POST for backchannel logout']);
    exit;
}

// Configuration
const LOG_FILE = '/var/log/moodle/backchannel_logout.log';
const MOODLE_ROOT = '/var/www/moodle';
const IDP_CERT_PATH = '/etc/shibboleth/idp-cert.pem';
const SESSION_TIMEOUT = 30; // seconds

// SAML namespaces
const SAML_PROTOCOL_NS = 'urn:oasis:names:tc:SAML:2.0:protocol';
const SAML_ASSERTION_NS = 'urn:oasis:names:tc:SAML:2.0:assertion';
const XMLDSIG_NS = 'http://www.w3.org/2000/09/xmldsig#';

/**
 * Log structured JSON message
 */
function log_message(string $level, string $message, array $context = []): void
{
    $entry = [
        'timestamp' => date('c'),
        'level' => $level,
        'message' => $message,
        'context' => $context,
        'source' => 'backchannel-handler'
    ];

    $logDir = dirname(LOG_FILE);
    if (!is_dir($logDir)) {
        @mkdir($logDir, 0755, true);
    }

    @file_put_contents(LOG_FILE, json_encode($entry) . "\n", FILE_APPEND | LOCK_EX);
}

/**
 * Send HTTP response with proper headers
 */
function send_response(int $statusCode, string $content, string $contentType = 'application/samlxml'): void
{
    http_response_code($statusCode);
    header("Content-Type: {$contentType}");
    header('Cache-Control: no-store, no-cache, must-revalidate');
    header('X-Content-Type-Options: nosniff');
    echo $content;
}

/**
 * Generate SAML LogoutResponse
 */
function generate_logout_response(
    string $inResponseTo,
    string $destination,
    string $issuer,
    string $status = 'urn:oasis:names:tc:SAML:2.0:status:Success'
): string {
    $id = '_' . bin2hex(random_bytes(16));
    $issueInstant = gmdate('Y-m-d\TH:i:s\Z');

    $response = <<<XML
<samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                      xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                      ID="{$id}"
                      InResponseTo="{$inResponseTo}"
                      Version="2.0"
                      IssueInstant="{$issueInstant}"
                      Destination="{$destination}">
    <saml:Issuer>{$issuer}</saml:Issuer>
    <samlp:Status>
        <samlp:StatusCode Value="{$status}"/>
    </samlp:Status>
</samlp:LogoutResponse>
XML;

    return $response;
}

/**
 * Generate SOAP envelope for SAML response
 */
function wrap_in_soap(string $samlMessage): string
{
    return <<<SOAP
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body>
        {$samlMessage}
    </soapenv:Body>
</soapenv:Envelope>
SOAP;
}

/**
 * Decode SAML request (handles base64 and deflate)
 */
function decode_saml_request(string $input): string
{
    // Try raw input first
    if (strpos($input, '<') !== false) {
        return $input;
    }

    // Try base64 decode
    $decoded = base64_decode($input, true);
    if ($decoded !== false && strpos($decoded, '<') !== false) {
        return $decoded;
    }

    // Try base64 + gzip decode (SAML binding)
    $decoded = base64_decode($input, true);
    if ($decoded !== false) {
        $decompressed = @gzinflate($decoded);
        if ($decompressed !== false) {
            return $decompressed;
        }
    }

    return $input;
}

/**
 * Parse SAML LogoutRequest
 */
function parse_logout_request(string $xml): array
{
    libxml_use_internal_errors(true);
    $doc = new DOMDocument();

    if (!$doc->loadXML($xml)) {
        $errors = libxml_get_errors();
        libxml_clear_errors();
        throw new InvalidArgumentException('Invalid XML: ' . implode(', ', array_map(function($e) {
            return $e->message;
        }, $errors)));
    }

    $xpath = new DOMXPath($doc);
    $xpath->registerNamespace('samlp', SAML_PROTOCOL_NS);
    $xpath->registerNamespace('saml', SAML_ASSERTION_NS);
    $xpath->registerNamespace('ds', XMLDSIG_NS);

    // Extract request ID
    $idNodes = $xpath->query('//samlp:LogoutRequest/@ID');
    $id = $idNodes->length > 0 ? $idNodes->item(0)->nodeValue : null;

    // Extract Issuer
    $issuerNodes = $xpath->query('//saml:Issuer');
    $issuer = $issuerNodes->length > 0 ? $issuerNodes->item(0)->nodeValue : null;

    // Extract NameID
    $nameIdNodes = $xpath->query('//saml:NameID');
    $nameId = $nameIdNodes->length > 0 ? $nameIdNodes->item(0)->nodeValue : null;
    $nameIdFormat = $nameIdNodes->length > 0 ? $nameIdNodes->item(0)->getAttribute('Format') : null;

    // Extract SessionIndex
    $sessionIndexNodes = $xpath->query('//samlp:SessionIndex');
    $sessionIndex = $sessionIndexNodes->length > 0 ? $sessionIndexNodes->item(0)->nodeValue : null;

    // Extract IssueInstant
    $issueInstantNodes = $xpath->query('//samlp:LogoutRequest/@IssueInstant');
    $issueInstant = $issueInstantNodes->length > 0 ? $issueInstantNodes->item(0)->nodeValue : null;

    return [
        'id' => $id,
        'issuer' => $issuer,
        'nameId' => $nameId,
        'nameIdFormat' => $nameIdFormat,
        'sessionIndex' => $sessionIndex,
        'issueInstant' => $issueInstant,
        'doc' => $doc,
        'xpath' => $xpath
    ];
}

/**
 * Verify SAML request signature
 */
function verify_signature(DOMDocument $doc, DOMXPath $xpath, string $idpCertPath): bool
{
    // Check if signature exists
    $signatureNodes = $xpath->query('//ds:Signature');
    if ($signatureNodes->length === 0) {
        log_message('warning', 'No signature found on logout request');
        return false;
    }

    // Load IdP certificate
    if (!file_exists($idpCertPath)) {
        log_message('error', 'IdP certificate not found', ['path' => $idpCertPath]);
        return false;
    }

    $idpCert = file_get_contents($idpCertPath);
    $idpCert = preg_replace('/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s+/', '', $idpCert);

    // Create public key
    $cert = "-----BEGIN CERTIFICATE-----\n" .
            chunk_split($idpCert, 64, "\n") .
            "-----END CERTIFICATE-----\n";

    $publicKey = openssl_pkey_get_public($cert);
    if ($publicKey === false) {
        log_message('error', 'Failed to load public key', ['error' => openssl_error_string()]);
        return false;
    }

    // Extract signature value
    $signatureValueNodes = $xpath->query('//ds:SignatureValue');
    if ($signatureValueNodes->length === 0) {
        return false;
    }
    $signatureValue = base64_decode(trim($signatureValueNodes->item(0)->nodeValue));

    // Extract signed data (canonicalized)
    $signedInfoNodes = $xpath->query('//ds:SignedInfo');
    if ($signedInfoNodes->length === 0) {
        return false;
    }

    // Get canonicalized SignedInfo
    $signedInfo = $signedInfoNodes->item(0);
    $canonicalSignedInfo = $signedInfo->C14N(true, false);

    // Get signature algorithm
    $algorithmNodes = $xpath->query('//ds:SignatureMethod/@Algorithm');
    $algorithm = $algorithmNodes->length > 0 ? $algorithmNodes->item(0)->nodeValue : XMLDSIG_NS . 'rsa-sha1';

    // Map algorithm to OpenSSL constant
    $opensslAlgorithm = OPENSSL_ALGO_SHA256;
    if (strpos($algorithm, 'rsa-sha1') !== false) {
        $opensslAlgorithm = OPENSSL_ALGO_SHA1;
    } elseif (strpos($algorithm, 'rsa-sha256') !== false) {
        $opensslAlgorithm = OPENSSL_ALGO_SHA256;
    } elseif (strpos($algorithm, 'rsa-sha384') !== false) {
        $opensslAlgorithm = OPENSSL_ALGO_SHA384;
    } elseif (strpos($algorithm, 'rsa-sha512') !== false) {
        $opensslAlgorithm = OPENSSL_ALGO_SHA512;
    }

    // Verify signature
    $result = openssl_verify($canonicalSignedInfo, $signatureValue, $publicKey, $opensslAlgorithm);

    return $result === 1;
}

/**
 * Terminate Moodle session by SessionIndex or NameID
 */
function terminate_moodle_session(string $sessionIndex, ?string $nameId, ?string $issuer): bool
{
    // Bootstrap Moodle if available
    if (is_dir(MOODLE_ROOT) && file_exists(MOODLE_ROOT . '/config.php')) {
        define('CLI_SCRIPT', true);
        require_once MOODLE_ROOT . '/config.php';

        try {
            global $DB, $SESSION;

            // Method 1: Find session by SessionIndex (if stored during login)
            if ($sessionIndex) {
                // Look up session by SAML session index
                // Moodle's auth_shibboleth plugin may store this in user_preferences or sessions
                $sessionRecord = $DB->get_record('sessions', ['sid' => $sessionIndex]);

                if ($sessionRecord) {
                    // Destroy the session
                    \core\session\manager::destroy($sessionRecord->sid);
                    log_message('info', 'Moodle session terminated by SessionIndex', [
                        'sessionIndex' => substr($sessionIndex, 0, 8) . '...'
                    ]);
                    return true;
                }
            }

            // Method 2: Find user by NameID and terminate all their sessions
            if ($nameId) {
                // Find user by username (NameID typically maps to username)
                $user = $DB->get_record('user', ['username' => $nameId, 'deleted' => 0]);

                if ($user) {
                    // Terminate all sessions for this user
                    \core\session\manager::destroy_user_sessions($user->id);
                    log_message('info', 'Moodle sessions terminated for user', [
                        'username' => $nameId,
                        'userId' => $user->id
                    ]);
                    return true;
                }
            }

            // Method 3: Use Shibboleth-specific session termination
            // Check if auth_shibboleth plugin is available
            if (class_exists('auth_plugin_shibboleth')) {
                $auth = get_auth_plugin('shibboleth');
                if (method_exists($auth, 'logout')) {
                    // Shibboleth logout handler
                    log_message('info', 'Invoking Shibboleth logout handler');
                    return true;
                }
            }

            log_message('warning', 'No matching Moodle session found', [
                'sessionIndex' => $sessionIndex ? substr($sessionIndex, 0, 8) . '...' : null,
                'nameId' => $nameId
            ]);

            // Return true anyway - session may have already expired
            return true;

        } catch (Exception $e) {
            log_message('error', 'Failed to terminate Moodle session', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return false;
        }
    }

    // Moodle not available - use direct session file cleanup
    log_message('info', 'Moodle bootstrap not available, using direct cleanup');
    return cleanup_session_files($sessionIndex, $nameId);
}

/**
 * Fallback: Clean up session files directly
 */
function cleanup_session_files(string $sessionIndex, ?string $nameId): bool
{
    $sessionPaths = [
        '/var/lib/php/sessions',
        '/var/lib/php8/sessions',
        '/tmp/sessions'
    ];

    $cleaned = 0;

    foreach ($sessionPaths as $path) {
        if (!is_dir($path)) {
            continue;
        }

        $files = glob($path . '/sess_*');
        foreach ($files as $file) {
            $content = @file_get_contents($file);
            if ($content === false) {
                continue;
            }

            // Check if session contains our session index or name ID
            if ($sessionIndex && strpos($content, $sessionIndex) !== false) {
                @unlink($file);
                $cleaned++;
            } elseif ($nameId && strpos($content, $nameId) !== false) {
                @unlink($file);
                $cleaned++;
            }
        }
    }

    log_message('info', 'Session file cleanup complete', ['files_cleaned' => $cleaned]);
    return $cleaned > 0;
}

/**
 * Main handler
 */
function handle_logout_request(): void
{
    $startTime = microtime(true);

    try {
        // Read request body
        $rawInput = file_get_contents('php://input');

        if (empty($rawInput)) {
            log_message('warning', 'Empty request body');
            send_response(400, generate_logout_response(
                'unknown',
                '',
                'moodle',
                'urn:oasis:names:tc:SAML:2.0:status:Requester'
            ));
            return;
        }

        // Handle SOAP envelope
        if (strpos($rawInput, 'soapenv:Envelope') !== false || strpos($rawInput, 'SOAP-ENV:Envelope') !== false) {
            // Extract SAML from SOAP body
            if (preg_match('/<soapenv:Body[^>]*>(.*?)<\/soapenv:Body>/s', $rawInput, $matches) ||
                preg_match('/<SOAP-ENV:Body[^>]*>(.*?)<\/SOAP-ENV:Body>/s', $rawInput, $matches)) {
                $rawInput = $matches[1];
            }
        }

        // Decode SAML request
        $samlRequest = decode_saml_request($rawInput);

        log_message('info', 'Received logout request', [
            'raw_length' => strlen($rawInput),
            'decoded_length' => strlen($samlRequest)
        ]);

        // Parse logout request
        $parsed = parse_logout_request($samlRequest);

        log_message('info', 'Parsed logout request', [
            'id' => $parsed['id'],
            'issuer' => $parsed['issuer'],
            'nameId' => $parsed['nameId'],
            'sessionIndex' => $parsed['sessionIndex'] ? substr($parsed['sessionIndex'], 0, 8) . '...' : null
        ]);

        // Verify signature
        $signatureValid = verify_signature($parsed['doc'], $parsed['xpath'], IDP_CERT_PATH);

        if (!$signatureValid) {
            log_message('error', 'Signature verification failed', [
                'requestId' => $parsed['id'],
                'issuer' => $parsed['issuer']
            ]);
            send_response(403, generate_logout_response(
                $parsed['id'] ?? 'unknown',
                $parsed['issuer'] ?? '',
                'moodle',
                'urn:oasis:names:tc:SAML:2.0:status:RequestDenied'
            ));
            return;
        }

        log_message('info', 'Signature verification successful');

        // Terminate Moodle session
        $terminated = terminate_moodle_session(
            $parsed['sessionIndex'],
            $parsed['nameId'],
            $parsed['issuer']
        );

        $duration = round((microtime(true) - $startTime) * 1000, 2);

        log_message('info', 'Backchannel logout completed', [
            'requestId' => $parsed['id'],
            'terminated' => $terminated,
            'duration_ms' => $duration
        ]);

        // Generate success response
        $response = generate_logout_response(
            $parsed['id'],
            $parsed['issuer'] ?? '',
            'https://' . ($_SERVER['HTTP_HOST'] ?? 'moodle.opendesk.example.com') . '/shibboleth'
        );

        // Wrap in SOAP if request was SOAP
        if (strpos(file_get_contents('php://input'), 'soapenv:Envelope') !== false) {
            $response = wrap_in_soap($response);
        }

        send_response(200, $response);

    } catch (InvalidArgumentException $e) {
        log_message('error', 'Invalid request', ['error' => $e->getMessage()]);
        send_response(400, generate_logout_response(
            'unknown',
            '',
            'moodle',
            'urn:oasis:names:tc:SAML:2.0:status:Requester'
        ));
    } catch (Exception $e) {
        log_message('error', 'Internal error', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        send_response(500, generate_logout_response(
            'unknown',
            '',
            'moodle',
            'urn:oasis:names:tc:SAML:2.0:status:Responder'
        ));
    }
}

// Execute handler
handle_logout_request();
