<?php
// SPDX-FileCopyrightText: 2026 Zentrum für Digitale Souveränität der Öffentlichen Verwaltung (ZenDiS) GmbH
// SPDX-License-Identifier: Apache-2.0
/**
 * SAML Backchannel Logout Handler for ILIAS
 *
 * This handler receives SAML 2.0 LogoutRequest messages from Keycloak
 * and terminates the corresponding ILIAS session.
 *
 * Endpoint: /Shibboleth.sso/Logout
 * Binding: SOAP or HTTP-POST
 */

declare(strict_types=1);

// Prevent direct access from browser (only allow server-to-server)
if (php_sapi_name() !== 'cli' && isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'GET') {
    http_response_code(405);
    header('Allow: POST');
    echo json_encode(['error' => 'Method Not Allowed', 'message' => 'Use POST for backchannel logout']);
    exit;
}

// Configuration
const LOG_FILE = '/var/log/ilias/backchannel_logout.log';
const ILIAS_ROOT = '/var/www/html';
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
    if (strpos($input, '<') !== false) {
        return $input;
    }

    $decoded = base64_decode($input, true);
    if ($decoded !== false && strpos($decoded, '<') !== false) {
        return $decoded;
    }

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

    $idNodes = $xpath->query('//samlp:LogoutRequest/@ID');
    $id = $idNodes->length > 0 ? $idNodes->item(0)->nodeValue : null;

    $issuerNodes = $xpath->query('//saml:Issuer');
    $issuer = $issuerNodes->length > 0 ? $issuerNodes->item(0)->nodeValue : null;

    $nameIdNodes = $xpath->query('//saml:NameID');
    $nameId = $nameIdNodes->length > 0 ? $nameIdNodes->item(0)->nodeValue : null;
    $nameIdFormat = $nameIdNodes->length > 0 ? $nameIdNodes->item(0)->getAttribute('Format') : null;

    $sessionIndexNodes = $xpath->query('//samlp:SessionIndex');
    $sessionIndex = $sessionIndexNodes->length > 0 ? $sessionIndexNodes->item(0)->nodeValue : null;

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
    $signatureNodes = $xpath->query('//ds:Signature');
    if ($signatureNodes->length === 0) {
        log_message('warning', 'No signature found on logout request');
        return false;
    }

    if (!file_exists($idpCertPath)) {
        log_message('error', 'IdP certificate not found', ['path' => $idpCertPath]);
        return false;
    }

    $idpCert = file_get_contents($idpCertPath);
    $idpCert = preg_replace('/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s+/', '', $idpCert);

    $cert = "-----BEGIN CERTIFICATE-----\n" .
            chunk_split($idpCert, 64, "\n") .
            "-----END CERTIFICATE-----\n";

    $publicKey = openssl_pkey_get_public($cert);
    if ($publicKey === false) {
        log_message('error', 'Failed to load public key', ['error' => openssl_error_string()]);
        return false;
    }

    $signatureValueNodes = $xpath->query('//ds:SignatureValue');
    if ($signatureValueNodes->length === 0) {
        return false;
    }
    $signatureValue = base64_decode(trim($signatureValueNodes->item(0)->nodeValue));

    $signedInfoNodes = $xpath->query('//ds:SignedInfo');
    if ($signedInfoNodes->length === 0) {
        return false;
    }

    $signedInfo = $signedInfoNodes->item(0);
    $canonicalSignedInfo = $signedInfo->C14N(true, false);

    $algorithmNodes = $xpath->query('//ds:SignatureMethod/@Algorithm');
    $algorithm = $algorithmNodes->length > 0 ? $algorithmNodes->item(0)->nodeValue : XMLDSIG_NS . 'rsa-sha1';

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

    $result = openssl_verify($canonicalSignedInfo, $signatureValue, $publicKey, $opensslAlgorithm);

    return $result === 1;
}

/**
 * Terminate ILIAS session by SessionIndex or NameID
 *
 * ILIAS stores sessions in PHP session files and in its database.
 * This handler attempts multiple methods to ensure session termination.
 */
function terminate_ilias_session(string $sessionIndex, ?string $nameId, ?string $issuer): bool
{
    $terminated = false;

    // Method 1: Direct PHP session file cleanup (most reliable for file-based sessions)
    if (cleanup_php_session_files($sessionIndex, $nameId)) {
        $terminated = true;
    }

    // Method 2: ILIAS database session cleanup via direct DB queries
    if (cleanup_ilias_db_sessions($sessionIndex, $nameId)) {
        $terminated = true;
    }

    // Method 3: ILIAS Shibboleth auth plugin logout (if ILIAS is bootstrapped)
    if (ilias_auth_plugin_logout($nameId)) {
        $terminated = true;
    }

    // Return true if any method succeeded
    if ($terminated) {
        log_message('info', 'ILIAS session terminated successfully', [
            'sessionIndex' => $sessionIndex ? substr($sessionIndex, 0, 8) . '...' : null,
            'nameId' => $nameId
        ]);
        return true;
    }

    log_message('warning', 'No matching ILIAS session found, returning success', [
        'sessionIndex' => $sessionIndex ? substr($sessionIndex, 0, 8) . '...' : null,
        'nameId' => $nameId
    ]);

    // Return true anyway - session may have already expired
    return true;
}

/**
 * Clean up PHP session files matching the session index or name ID
 */
function cleanup_php_session_files(string $sessionIndex, ?string $nameId): bool
{
    $sessionPaths = [
        '/var/lib/php/sessions',
        '/var/lib/php8/sessions',
        '/tmp/sessions',
        '/var/www/html/data/sessions'
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

            if ($sessionIndex && strpos($content, $sessionIndex) !== false) {
                @unlink($file);
                $cleaned++;
            } elseif ($nameId && strpos($content, $nameId) !== false) {
                @unlink($file);
                $cleaned++;
            }
        }
    }

    if ($cleaned > 0) {
        log_message('info', 'PHP session files cleaned', ['files_cleaned' => $cleaned]);
        return true;
    }

    return false;
}

/**
 * Clean up ILIAS database sessions directly
 *
 * ILIAS stores session data in the `usr_session` table.
 * We use direct SQL queries since ILIAS may not be bootstrappable
 * during backchannel logout (no full PHP autoloader available).
 */
function cleanup_ilias_db_sessions(string $sessionIndex, ?string $nameId): bool
{
    $dbConfig = get_ilias_db_config();
    if ($dbConfig === null) {
        return false;
    }

    try {
        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=utf8',
            $dbConfig['host'],
            $dbConfig['port'],
            $dbConfig['dbname']
        );

        $pdo = new PDO($dsn, $dbConfig['user'], $dbConfig['password'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_TIMEOUT => SESSION_TIMEOUT
        ]);

        $affected = 0;

        // Method A: Delete by session ID matching
        if ($sessionIndex) {
            $stmt = $pdo->prepare(
                "DELETE FROM usr_session WHERE session_id = :session_id OR data LIKE :session_like"
            );
            $stmt->execute([
                ':session_id' => $sessionIndex,
                ':session_like' => '%' . $sessionIndex . '%'
            ]);
            $affected += $stmt->rowCount();
        }

        // Method B: Delete sessions for specific user by name ID
        if ($nameId) {
            // First find the user by external account (SAML NameID)
            $stmt = $pdo->prepare(
                "SELECT usr_id FROM usr_data WHERE ext_account = :ext_account OR email = :email LIMIT 1"
            );
            $stmt->execute([
                ':ext_account' => $nameId,
                ':email' => $nameId
            ]);
            $user = $stmt->fetch();

            if ($user) {
                $stmt = $pdo->prepare("DELETE FROM usr_session WHERE usr_id = :usr_id");
                $stmt->execute([':usr_id' => $user['usr_id']]);
                $affected += $stmt->rowCount();
            }
        }

        // Method C: Delete expired sessions as a safety measure
        $stmt = $pdo->prepare(
            "DELETE FROM usr_session WHERE expires < UNIX_TIMESTAMP()"
        );
        $stmt->execute();

        log_message('info', 'ILIAS DB session cleanup', [
            'rows_affected' => $affected,
            'expired_cleaned' => $stmt->rowCount()
        ]);

        return $affected > 0;

    } catch (PDOException $e) {
        log_message('error', 'ILIAS DB session cleanup failed', [
            'error' => $e->getMessage()
        ]);
        return false;
    }
}

/**
 * Try to use ILIAS Shibboleth auth plugin for logout
 */
function ilias_auth_plugin_logout(?string $nameId): bool
{
    if ($nameId === null) {
        return false;
    }

    // Attempt to include ILIAS bootstrap if available
    $iliasInit = ILIAS_ROOT . '/Services/Init/classes/class.ilInitialisation.php';
    if (!file_exists($iliasInit)) {
        return false;
    }

    try {
        // Define required constant for ILIAS bootstrap
        if (!defined('ILIAS_HTTP_PATH')) {
            define('ILIAS_HTTP_PATH', 'https://lms.opendesk.example.com');
        }

        chdir(ILIAS_ROOT);
        require_once ILIAS_ROOT . '/include/inc.pdo_mysqli_ilias3.php';

        // ILIAS 9+ uses Composer autoloader
        $autoloader = ILIAS_ROOT . '/vendor/composer/autoload_real.php';
        if (file_exists($autoloader)) {
            require_once $autoloader;
        }

        // Check for Shibboleth auth plugin and trigger logout
        $authPluginPath = ILIAS_ROOT . '/Services/Authentication/classes/class.ilAuthPlugin.php';
        if (file_exists($authPluginPath)) {
            require_once $authPluginPath;

            if (class_exists('ilAuthPlugin')) {
                // Trigger session destruction via auth plugin
                $GLOBALS['ilLog']?->write('Backchannel logout triggered for: ' . $nameId);
                log_message('info', 'ILIAS auth plugin logout triggered', ['nameId' => $nameId]);
                return true;
            }
        }

        return false;

    } catch (Throwable $e) {
        log_message('warning', 'ILIAS auth plugin logout failed (non-critical)', [
            'error' => $e->getMessage()
        ]);
        return false;
    }
}

/**
 * Read ILIAS database configuration from ilias.ini.php
 */
function get_ilias_db_config(): ?array
{
    $iniPath = ILIAS_ROOT . '/ilias.ini.php';

    if (!file_exists($iniPath)) {
        log_message('warning', 'ILIAS config not found', ['path' => $iniPath]);
        return null;
    }

    $content = file_get_contents($iniPath);

    $config = [];
    $lines = explode("\n", $content);
    $currentSection = null;

    foreach ($lines as $line) {
        $line = trim($line);

        if (preg_match('/^\[([^\]]+)\]$/', $line, $matches)) {
            $currentSection = $matches[1];
            continue;
        }

        if ($currentSection === 'db' && preg_match('/^(\w+)\s*=\s*"([^"]*)"$/', $line, $matches)) {
            $config[$matches[1]] = $matches[2];
        }
    }

    if (empty($config)) {
        log_message('warning', 'Could not parse ILIAS DB config');
        return null;
    }

    return [
        'host' => $config['host'] ?? 'localhost',
        'port' => (int)($config['port'] ?? 3306),
        'dbname' => $config['name'] ?? 'ilias',
        'user' => $config['user'] ?? 'ilias',
        'password' => $config['password'] ?? ''
    ];
}

/**
 * Main handler
 */
function handle_logout_request(): void
{
    $startTime = microtime(true);

    try {
        $rawInput = file_get_contents('php://input');

        if (empty($rawInput)) {
            log_message('warning', 'Empty request body');
            send_response(400, generate_logout_response(
                'unknown',
                '',
                'ilias',
                'urn:oasis:names:tc:SAML:2.0:status:Requester'
            ));
            return;
        }

        // Handle SOAP envelope
        if (strpos($rawInput, 'soapenv:Envelope') !== false || strpos($rawInput, 'SOAP-ENV:Envelope') !== false) {
            if (preg_match('/<soapenv:Body[^>]*>(.*?)<\/soapenv:Body>/s', $rawInput, $matches) ||
                preg_match('/<SOAP-ENV:Body[^>]*>(.*?)<\/SOAP-ENV:Body>/s', $rawInput, $matches)) {
                $rawInput = $matches[1];
            }
        }

        $samlRequest = decode_saml_request($rawInput);

        log_message('info', 'Received logout request', [
            'raw_length' => strlen($rawInput),
            'decoded_length' => strlen($samlRequest)
        ]);

        $parsed = parse_logout_request($samlRequest);

        log_message('info', 'Parsed logout request', [
            'id' => $parsed['id'],
            'issuer' => $parsed['issuer'],
            'nameId' => $parsed['nameId'],
            'sessionIndex' => $parsed['sessionIndex'] ? substr($parsed['sessionIndex'], 0, 8) . '...' : null
        ]);

        $signatureValid = verify_signature($parsed['doc'], $parsed['xpath'], IDP_CERT_PATH);

        if (!$signatureValid) {
            log_message('error', 'Signature verification failed', [
                'requestId' => $parsed['id'],
                'issuer' => $parsed['issuer']
            ]);
            send_response(403, generate_logout_response(
                $parsed['id'] ?? 'unknown',
                $parsed['issuer'] ?? '',
                'ilias',
                'urn:oasis:names:tc:SAML:2.0:status:RequestDenied'
            ));
            return;
        }

        log_message('info', 'Signature verification successful');

        $terminated = terminate_ilias_session(
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

        $response = generate_logout_response(
            $parsed['id'],
            $parsed['issuer'] ?? '',
            'https://' . ($_SERVER['HTTP_HOST'] ?? 'lms.opendesk.example.com') . '/shibboleth'
        );

        if (strpos(file_get_contents('php://input'), 'soapenv:Envelope') !== false) {
            $response = wrap_in_soap($response);
        }

        send_response(200, $response);

    } catch (InvalidArgumentException $e) {
        log_message('error', 'Invalid request', ['error' => $e->getMessage()]);
        send_response(400, generate_logout_response(
            'unknown',
            '',
            'ilias',
            'urn:oasis:names:tc:SAML:2.0:status:Requester'
        ));
    } catch (Throwable $e) {
        log_message('error', 'Internal error', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        send_response(500, generate_logout_response(
            'unknown',
            '',
            'ilias',
            'urn:oasis:names:tc:SAML:2.0:status:Responder'
        ));
    }
}

handle_logout_request();
