# pull from official PHP-FPM
FROM php:7.4.13-fpm-alpine3.12

# install our required packages
RUN apk update && \
    apk --no-cache add jpeg-dev libpng-dev nginx nginx-mod-http-dav-ext php7-curl php7-json \
                        php7-xml php7-mbstring php7-openssl php7-dom php7-exif php7-fileinfo \
                        php7-pdo php7-phar php7-simplexml php7-tokenizer php7-xmlwriter php7-posix \
                        php7-session php7-gd php7-opcache php7-pdo_mysql && \
    docker-php-ext-configure gd --with-jpeg && \
    docker-php-ext-install exif gd

# remove our APK cache
RUN rm -rf /var/cache/apk/*

# copy our dependant files
COPY resources/ /

# create our app directory
RUN mkdir -p /app/public && \
    echo "<?php phpinfo(); ?>" > /app/public/index.php && \
    chown -R nginx:www-data /app

# Configure nginx service
RUN	mkdir -p /run/nginx && \
    chgrp -R nginx /run/nginx && \
	mkdir -p /etc/nginx/sites-enabled && \
	rm -f /etc/nginx/conf.d/default.conf && \
	ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Set permissions for our entrypoint
RUN chmod a+x /entrypoint.sh && \
    chown nobody:nobody /entrypoint.sh

# Expose nginx
EXPOSE 80 80

# run our entrypoint file
ENTRYPOINT "/entrypoint.sh"

# set our working directory to /app
WORKDIR /app