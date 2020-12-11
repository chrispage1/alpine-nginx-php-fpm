# pull from official PHP-FPM
FROM php:7.4.13-fpm-alpine3.12

# install our required packages
RUN apk update && \
    apk --no-cache add jpeg-dev libpng-dev nginx nginx-mod-http-dav-ext && \
    docker-php-ext-configure gd --with-jpeg && \
    docker-php-ext-install exif gd pdo_mysql opcache json

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


# Configure nginx service
RUN	mkdir -p /run/nginx && \
    chgrp -R nginx /run/nginx && \
	mkdir -p /etc/nginx/sites-enabled && \
	rm -f /etc/nginx/conf.d/default.conf && \
	ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Update our php-fpm file
RUN mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf.default
RUN mv /etc/php-fpm/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# Set permissions for our entrypoint
RUN chmod a+x /entrypoint.sh && \
    chown nobody:nobody /entrypoint.sh

# Expose nginx
EXPOSE 80 80

# run our entrypoint file
ENTRYPOINT "/entrypoint.sh"

# set our working directory to /app
WORKDIR /app