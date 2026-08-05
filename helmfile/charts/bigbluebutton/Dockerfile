FROM ruby:3.3-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       apache2 \
       build-essential \
       libpq-dev \
       libsqlite3-dev \
       libyaml-dev \
       curl \
       gnupg \
       git \
       ca-certificates \
       shibboleth-sp-common \
       shibboleth-sp-utils \
       libapache2-mod-shib \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && gem install bundler --no-document \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod proxy proxy_http headers ssl rewrite shib && \
    mkdir -p /var/log/shibboleth /var/run/shibboleth && \
    chown -R www-data:www-data /var/log/shibboleth /var/run/shibboleth /etc/shibboleth

WORKDIR /opt/greenlight

RUN git clone --depth 1 --branch release-3.8.0 \
        https://github.com/bigbluebutton/greenlight.git \
        /opt/greenlight && \
    cd /opt/greenlight && \
    bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle config set frozen false && \
    bundle install -j4 && \
    npm install && \
    RAILS_ENV=production SECRET_KEY_BASE=precompile_placeholder bundle exec rails assets:precompile && \
    chown -R www-data:www-data /opt/greenlight

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY greenlight.conf /etc/apache2/sites-available/greenlight.conf
RUN a2dissite 000-default.conf && \
    a2ensite greenlight.conf

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
