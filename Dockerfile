# pull from official PHP-FPM
FROM php:8.0.0-fpm-alpine3.12

# install our required packages
RUN apk update && \
    apk --no-cache add jpeg-dev libpng-dev nginx nginx-mod-http-dav-ext php7 php7-common php7-curl php7-json \
                        php8-fpm php8-xml php8-mbstring php8-openssl php8-dom php8-exif php8-fileinfo \
                        php8-pdo php8-phar php8-simplexml php8-tokenizer php8-xmlwriter php8-posix \
                        php8-session php8-gd php8-opcache php8-pdo_mysql && \
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