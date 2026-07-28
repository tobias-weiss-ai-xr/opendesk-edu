# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
FROM srsolutions/ilias:9-php8.2-apache

# Install Shibboleth SP Apache module
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libapache2-mod-shib \
        opensaml-schemas \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Enable the Shibboleth Apache module
    a2enmod shib ssl && \
    # Create required directories
    mkdir -p /var/log/shibboleth /var/run/shibboleth /etc/apache2/ssl && \
    chmod 755 /var/log/shibboleth /var/run/shibboleth && \
    # Generate self-signed cert for internal SSL (shibboleth handlerSSL support)
    openssl req -x509 -newkey rsa:4096 -keyout /etc/apache2/ssl/apache.key \
        -out /etc/apache2/ssl/apache.crt -days 3650 -nodes \
        -subj "/CN=ilias/O=openDesk/C=DE" && \
    chmod 644 /etc/apache2/ssl/apache.key /etc/apache2/ssl/apache.crt

# Copy default Shibboleth configuration templates
# Runtime config is mounted via ConfigMap, but these provide defaults
COPY shibboleth2.xml /etc/shibboleth/shibboleth2.xml

# Health check: verify shibd is running and Apache has mod_shib loaded
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD shibd -t && apache2ctl -M 2>/dev/null | grep -q shib2_userdata || exit 1

LABEL org.opencontainers.image.title="openDesk ILIAS with Shibboleth SP" \
      org.opencontainers.image.description="ILIAS LMS 9 with Apache and Shibboleth SP 3" \
      org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-edu" \
      org.opencontainers.image.version="9-php8.2-apache" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later"
