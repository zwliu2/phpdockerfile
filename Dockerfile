# php 7.4 fpm
FROM php:7.4-fpm

RUN echo "deb http://mirrors.aliyun.com/debian buster main contrib non-free" > /etc/apt/sources.list && \
    echo "deb-src http://mirrors.aliyun.com/debian buster main contrib non-free" >> /etc/apt/sources.list  && \
    echo "deb http://mirrors.aliyun.com/debian buster-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb-src http://mirrors.aliyun.com/debian buster-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb-src http://mirrors.aliyun.com/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libjpeg-dev \
        zlib1g-dev \
        libzip-dev \
        nginx \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-webp=/usr/include/webp --with-jpeg=/usr/include --with-freetype=/usr/include/freetype2 \
    && docker-php-ext-install -j$(nproc) gd opcache pcntl \
    && docker-php-ext-install sockets \
    && docker-php-ext-install pod_mysql \
    && docker-php-ext-install zip

RUN pecl install redis \
    && docker-php-ext-enable redis

RUN curl -fsSL 'https://github.com/alanxz/rabbitmq-c/releases/download/v0.7.1/rabbitmq-c-0.7.1.tar.gz' -o rabbitmq-c.tar.gz \
    && mkdir -p rabbitmq-c \
    && tar -zxvf rabbitmq-c.tar.gz -C rabbitmq-c --strip-components=1 \
    && rm rabbitmq-c.tar.gz \
    && ( \
        cd  rabbitmq-c \
        && ./configure --prefix=/usr/local/rabbitmq-c \
        && make -j$(nproc) \
        && make install \
        && cp librabbitmq/amqp_ssl_socket.h /usr/include \
        && cd ..\
    ) \
    && rm -rf ./rabbitmq-c

RUN curl -fsSL 'http://pecl.php.net/get/amqp-1.9.4.tgz' -o amqp.tgz \
    && mkdir -p amqp \
    && tar -zxvf amqp.tgz -C amqp --strip-components=1 \
    && rm amqp.tgz \
    && ( \
        cd  amqp\
        && phpize \
        && ./configure --with-php-config=/usr/local/bin/php-config --with-amqp --with-librabbitmq-dir=/usr/local/rabbitmq-c \
        && make -j$(nproc) \
        && make install \
    ) \
    && docker-php-ext-enable amqp \
    && rm -rf ./amqp

COPY ./php.ini /usr/local/etc/php/conf.d/runtime.ini
COPY ./nginx.conf /etc/nginx/nginx.conf

#COPY .. /var/www/html/
