# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
FROM docker.io/library/mariadb:11.4.4

# Create compatibility symlinks (MariaDB 11.4 uses mariadb-* names)
RUN ln -sf /usr/bin/mariadb /usr/bin/mysql && \
    ln -sf /usr/bin/mariadb-admin /usr/bin/mysqladmin && \
    ln -sf /usr/bin/mariadb-check /usr/bin/mysqlcheck && \
    ln -sf /usr/bin/mariadb-dump /usr/bin/mysqldump && \
    ln -sf /usr/bin/mariadb-upgrade /usr/bin/mysqlupgrade && \
    ln -sf /usr/bin/mariadb-install-db /usr/bin/mysql_install_db

# ILIAS-optimized MariaDB configuration
RUN { \
    echo '[mysqld]'; \
    echo 'skip-name-resolve'; \
    echo 'explicit_defaults_for_timestamp'; \
    echo 'innodb_large_prefix=OFF'; \
    echo 'sql_mode='; \
    echo 'character-set-server=utf8'; \
    echo 'collation-server=utf8_general_ci'; \
    echo 'max_allowed_packet=32M'; \
    echo 'join_buffer_size=256M'; \
    echo 'table_open_cache=4096'; \
    echo 'innodb_buffer_pool_size=2G'; \
    echo 'innodb_file_per_table=1'; \
    echo 'max_connections=500'; \
    echo 'log_bin=mysql-bin'; \
    echo 'expire_logs_days=14'; \
    echo 'slow_query_log=1'; \
    echo 'long_query_time=10.0'; \
    echo 'binlog_expire_logs_seconds=2592000'; \
} | tee /etc/mysql/conf.d/ilias.cnf

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD mariadb-admin ping -u root --silent || exit 1

LABEL org.opencontainers.image.title="openDesk ILIAS MariaDB" \
      org.opencontainers.image.description="MariaDB 11.4 with ILIAS-optimized defaults" \
      org.opencontainers.image.source="https://github.com/opendesk-edu/opendesk-edu" \
      org.opencontainers.image.licenses="Apache-2.0"
