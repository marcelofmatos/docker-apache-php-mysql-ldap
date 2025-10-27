FROM php:7.4-apache

RUN docker-php-ext-configure mysqli \
    && docker-php-ext-install mysqli 

RUN docker-php-ext-configure pdo_mysql \
    && docker-php-ext-install pdo_mysql 

RUN apt update \
    && apt install libldap2-dev libzip-dev libpng-dev -y \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install ldap \
    && docker-php-ext-install zip \
    && docker-php-ext-install gd \
    && apt remove libldap2-dev libzip-dev libpng-dev -y \
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

# Instalar bash-completion e configurar autocomplete para Artisan
RUN apt update \
    && apt install -y bash-completion \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://raw.githubusercontent.com/ahinkle/laravel-bash-completion/master/laravel-artisan-bash-completion \
       -o /etc/bash_completion.d/artisan \
    && chmod +x /etc/bash_completion.d/artisan \
    && echo 'alias artisan="php artisan"' >> /root/.bashrc \
    && echo '[ -f /etc/bash_completion.d/artisan ] && source /etc/bash_completion.d/artisan' >> /root/.bashrc
