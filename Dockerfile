# pull from official PHP-FPM
FROM php:7.4.15-fpm-alpine3.13

# update our apk library
RUN apk update

# grab php extensions package manager & install packages
ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/1.2.15/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions redis pcntl exif gd pdo_mysql opcache json

# tidy up a little
RUN rm -rf /var/cache/apk/*

# copy our dependant files
COPY resources/ /

# create our app directory with default phpinfo
RUN mkdir -p /app/public && \
    echo "<?php phpinfo(); ?>" > /app/public/index.php && \
    chown -R nginx:www-data /app

# update our php.ini file
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
        sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 512M|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|max_file_uploads = 20|max_file_uploads = 60|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 512M|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|post_max_size = 8M|post_max_size = 512M|' "$PHP_INI_DIR/php.ini"

# optimise php-fpm's opcache
RUN printf "\n\
opcache.memory_consumption=256\n\
opcache.validate_timestamps=0\n\
opcache.max_accelerated_files=10000\n\
" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

# move our healthcheck file
RUN mv /etc/php-fpm/php-fpm-healthcheck /usr/local/sbin && \
       chmod +x /usr/local/sbin/php-fpm-healthcheck

# configure nginx service
RUN	mkdir -p /run/nginx && \
    chgrp -R nginx /run/nginx && \
	mkdir -p /etc/nginx/sites-enabled && \
	rm -f /etc/nginx/conf.d/default.conf && \
	ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/

# replace our php-fpm files
RUN mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.default
RUN mv /etc/php-fpm/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# Expose nginx & PHP-FPM
EXPOSE 80 80
EXPOSE 9000 9000

# run php-fpm
CMD php-fpm

# set our working directory to /app for future builds
WORKDIR /app