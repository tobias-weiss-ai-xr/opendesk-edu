FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       apache2 \
       libapache2-mod-php \
       php \
       php-mysql \
       php-pgsql \
       php-xml \
       php-curl \
       php-gd \
       php-intl \
       php-mbstring \
       php-soap \
       php-zip \
       php-json \
       php-opcache \
       php-ldap \
       php-redis \
       shibboleth-sp-common \
       shibboleth-sp-utils \
       libapache2-mod-shib \
       git \
       ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN a2enmod php8.1 rewrite ssl headers proxy proxy_http shib && \
    mkdir -p /var/log/shibboleth /var/run/shibboleth && \
    chown -R www-data:www-data /var/log/shibboleth /var/run/shibboleth /etc/shibboleth && \
    echo "max_input_vars = 6000\npost_max_size = 200M\nupload_max_filesize = 200M" > /etc/php/8.1/apache2/conf.d/99-moodle.ini && \
    echo "max_input_vars = 6000\npost_max_size = 200M\nupload_max_filesize = 200M" > /etc/php/8.1/cli/conf.d/99-moodle.ini

RUN rm -rf /var/www/html/* && \
    git clone --depth 1 --branch MOODLE_404_STABLE \
        https://github.com/moodle/moodle.git \
        /var/www/html && \
    chown -R www-data:www-data /var/www/html && \
    mkdir -p /var/www/moodledata && \
    chown -R www-data:www-data /var/www/moodledata && \
    mkdir -p /var/www/html/auth/shibboleth && \
    chown -R www-data:www-data /var/www/html/auth/shibboleth

COPY config.php /var/www/html/config.php
RUN chown www-data:www-data /var/www/html/config.php

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
