# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0
FROM php:8.4-apache

USER root

# Install required PHP extensions and system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpng-dev \
        libjpeg-dev \
        libfreetype-dev \
        libzip-dev \
        libicu-dev \
        libcurl4-openssl-dev \
        unzip \
        curl \
        git && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        gd \
        intl \
        zip \
        mbstring \
        fileinfo \
        curl \
        opcache && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install TYPO3 CMS via Composer (Composer mode)
RUN composer create-project typo3/cms-core:^13.4 /var/www/html --no-dev --no-interaction
RUN composer require causal/oidc --no-interaction

# Configure Apache document root for TYPO3 Composer mode
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Set ownership and permissions for www-data (UID 33)
RUN chown -R www-data:www-data /var/www/html && \
    mkdir -p /var/www/html/fileadmin /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/fileadmin /var/www/html/var

USER www-data
