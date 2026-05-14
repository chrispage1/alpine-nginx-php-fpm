# pull from official PHP-FPM
FROM --platform=linux/amd64 php:8.4-fpm-alpine

# update our apk library
RUN apk update
RUN apk upgrade --no-cache

# install nginx
RUN apk --no-cache add nginx fcgi jpegoptim

# grab php extensions package manager & install packages
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/sbin/
RUN chmod +x /usr/local/sbin/install-php-extensions
RUN install-php-extensions redis pcntl exif gd pdo_mysql opcache zip intl
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
        sed -i 's|max_file_uploads = 20|max_file_uploads = 60|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20M|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|post_max_size = 8M|post_max_size = 20M|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|output_buffering = 0|output_buffering = 4096|' "$PHP_INI_DIR/php.ini" && \
        sed -i 's|memory_limit = 128M|memory_limit = 64M|' "$PHP_INI_DIR/php.ini"

RUN printf "\n\
error_log=/proc/self/fd/2\n\
" >> /usr/local/etc/php/conf.d/php-tuning.ini

# optimise php-fpm's opcache
RUN rm /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
RUN printf "\
zend_extension=opcache\n\\n\
opcache.memory_consumption=128M\n\
opcache.interned_strings_buffer=15M\n\
opcache.jit_buffer_size=128M\n\
opcache.max_accelerated_files=15000\n\
opcache.validate_timestamps=0\n\
opcache.save_comments=1\n\
opcache.consistency_checks=0\n\
opcache.jit=tracing\n\
opcache.fast_shutdown=1\n\
opcache.enable=1\n\
opcache.enable_cli=1\n\
" > /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

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
EXPOSE 8080 8080
EXPOSE 9000 9000

# set our file permissions
RUN chown -R 82:82 /app \
    /var/lib/nginx \
    /var/log/nginx \
    /run/nginx \
    /usr/local/var

# set our user as www-data
USER 82

# run php-fpm
CMD php-fpm

# set our working directory to /app for future builds
WORKDIR /app