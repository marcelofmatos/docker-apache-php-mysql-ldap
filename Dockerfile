FROM php:7.4-apache

RUN docker-php-ext-configure mysqli \
    && docker-php-ext-install mysqli 

RUN docker-php-ext-configure pdo_mysql \
    && docker-php-ext-install pdo_mysql 

RUN apt update \
    && apt install libldap2-dev -y \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install ldap \
    && apt remove libldap2-dev -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite 
