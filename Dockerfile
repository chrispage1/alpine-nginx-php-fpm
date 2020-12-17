# pull from official PHP-FPM
FROM php:7.4.13-fpm-alpine3.12

# install our required packages
RUN apk update && \
    apk --no-cache add jpeg-dev fcgi libpng-dev nginx nginx-mod-http-dav-ext $PHPIZE_DEPS && \
    pecl install redis && \
    docker-php-ext-configure gd --with-jpeg && \
    docker-php-ext-install exif gd pdo_mysql opcache json && \
    docker-php-ext-enable redis

# remove our APK cache
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

# Move our healthcheck file
RUN mv /etc/php-fpm/php-fpm-healthcheck /usr/local/sbin && \
       chmod a+x /usr/local/sbin/php-fpm-healthcheck


# Configure nginx service
RUN	mkdir -p /run/nginx && \
    chgrp -R nginx /run/nginx && \
	mkdir -p /etc/nginx/sites-enabled && \
	rm -f /etc/nginx/conf.d/default.conf && \
	ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/

# Update our php-fpm file
RUN mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.default
RUN mv /etc/php-fpm/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# Expose nginx & PHP-FPM
EXPOSE 80 80
EXPOSE 9000 9000

CMD php-fpm

# set our working directory to /app
WORKDIR /app