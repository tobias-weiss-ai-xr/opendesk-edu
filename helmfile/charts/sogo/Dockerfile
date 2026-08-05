# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install SOGo and runtime deps
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        supervisor \
        apache2 \
        libapache2-mod-proxy-uwsgi \
        sogo \
        sogo-activesync \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod proxy proxy_uwsgi proxy_http headers rewrite

# Default Apache SOGo vhost
COPY apache-sogo.conf /etc/apache2/sites-available/sogo.conf
RUN ln -sf /etc/apache2/sites-available/sogo.conf /etc/apache2/sites-enabled/000-sogo.conf

EXPOSE 80

# Entrypoint is provided by ConfigMap at runtime
CMD ["sleep", "infinity"]
