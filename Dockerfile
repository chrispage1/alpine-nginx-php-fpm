# pull from official PHP-FPM
FROM php:7.4.15-fpm-alpine3.13

# install our required packages
RUN apk update && \
    apk --no-cache add jpeg-dev fcgi libpng-dev libwebp-dev nginx nginx-mod-http-dav-ext pcre-dev $PHPIZE_DEPS && \
    docker-php-ext-configure gd --with-jpeg --with-webp && \
    docker-php-ext-install exif gd pdo_mysql opcache json
    
# install phpredis
RUN pecl install redis \
    && docker-php-ext-enable redis.so

# remove caches etc.
RUN rm -rf /var/cache/apk/*

# copy our dependant files
COPY resources/ /

# create our app directory
RUN mkdir -p /app/public && \
    echo "<?php phpinfo(); ?>" > /app/public/index.php && \
    chown -R nginx:www-data /app

# update our php.ini file
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
        sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 512M|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|max_file_uploads = 20|max_file_uploads = 60|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 512M|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|post_max_size = 8M|post_max_size = 512M|' "$PHP_INI_DIR/php.ini"

# move our healthcheck file
RUN mv /etc/php-fpm/php-fpm-healthcheck /usr/local/sbin && \
       chmod a+x /usr/local/sbin/php-fpm-healthcheck


# configure nginx service
RUN	mkdir -p /run/nginx && \
    chgrp -R nginx /run/nginx && \
	mkdir -p /etc/nginx/sites-enabled && \
	rm -f /etc/nginx/conf.d/default.conf && \
	ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/

# update our php-fpm file
RUN mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.default
RUN mv /etc/php-fpm/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# Expose nginx & PHP-FPM
EXPOSE 80 80
EXPOSE 9000 9000

CMD php-fpm

# set our working directory to /app
WORKDIR /app