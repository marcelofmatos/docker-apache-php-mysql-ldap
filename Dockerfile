FROM php:7.4-apache

RUN docker-php-ext-configure mysqli \
    && docker-php-ext-install mysqli 

RUN docker-php-ext-configure pdo_mysql \
    && docker-php-ext-install pdo_mysql 

RUN apt update \
    && apt install libldap2-dev libzip-dev -y \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install ldap \
    && docker-php-ext-install zip \
    && apt remove libldap2-dev libzip-dev -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

# Instalar dependências necessárias para o Composer
RUN apt update \
    && apt install -y git unzip curl \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Verificar instalação
RUN composer --version
