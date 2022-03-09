FROM php:5.6-apache

RUN docker-php-ext-install mysqli 

RUN docker-php-ext-install pdo_mysql 

RUN apt update \
    && apt install libldb-dev libldap2-dev libpng-dev zlib1g-dev -y \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install ldap \
    && docker-php-ext-install gd \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install zip \
    && apt remove libldb-dev libldap2-dev -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite 
