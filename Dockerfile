FROM php:5.6-apache

RUN docker-php-ext-install mysqli 

RUN docker-php-ext-install pdo_mysql 

# freetype fonts for captcha
RUN apt update && apt install wget -y \
    && rm -rf /var/lib/apt/lists/* \
    && wget http://iweb.dl.sourceforge.net/project/freetype/freetype2/2.5.0/freetype-2.5.0.1.tar.bz2 \
    && tar xvfj freetype-2.5.0.1.tar.bz2 \
    && cd freetype-2.5.0.1 \
    && ./configure --without-png \
    && make \
    && make install

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libmcrypt-dev \
        libpng-dev \
        libjpeg-dev \
        libpng-dev \
    && docker-php-ext-install iconv mcrypt \
    && docker-php-ext-configure gd \
        --enable-gd-native-ttf \
        --with-freetype-dir=/usr/include/freetype2 \
        --with-png-dir=/usr/include \
        --with-jpeg-dir=/usr/include \
    && docker-php-ext-install gd \
    && docker-php-ext-enable gd \
    && docker-php-ext-install mbstring \
    && rm -rf /var/lib/apt/lists/*

RUN apt update \
    && apt install libldb-dev libldap2-dev libpng-dev zlib1g-dev -y \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install ldap \
    && docker-php-ext-enable ldap \
    && docker-php-ext-configure gd \
    && docker-php-ext-install zip \
    && apt remove libldb-dev libldap2-dev -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*


RUN a2enmod rewrite 
