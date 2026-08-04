# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors

# openDesk MariaDB Dockerfile
# Based on: eclipse-temurin:21-jre
# Version: 11.4.4
# OpenSpec: FR-BUILD-007 (Dockerfile compatibility)

FROM eclipse-temurin:21-jre

# Set environment variables
ARG MARIADB_VERSION=11.4.4
ENV MARIADB_VERSION=${MARIADB_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Berlin

# Install MariaDB
RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server=${MARIADB_VERSION}* \
    mariadb-client=${MARIADB_VERSION}* \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /docker-entrypoint-initdb.d

# Copy configuration
COPY config/my.cnf /etc/mysql/conf.d/opendesk.cnf

# Copy initialization scripts
COPY scripts/init-sql.sh /docker-entrypoint-initdb.d/

# Create data directory
RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql && \
    chmod -R 755 /var/lib/mysql

# Security hardening (FR-IMAGE-001)
RUN useradd -r -u 999 -g mysql mysql 2>/dev/null || true && \
    usermod -u 999 mysql && \
    groupmod -g 999 mysql

# Expose port
EXPOSE 3306

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD mariadb-admin ping -u root --password=$${MARIADB_ROOT_PASSWORD}

# Volume declarations
VOLUME ["/var/lib/mysql", "/var/log/mysql", "/etc/mysql/conf.d"]

# Set working directory
WORKDIR /var/lib/mysql

# Run as non-root (FR-IMAGE-001)
USER mysql

# Entrypoint
CMD ["mariadbd", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]
