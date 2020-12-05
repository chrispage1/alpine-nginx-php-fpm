FROM alpine:edge

# install packages
RUN apk update && \
    apk --no-cache add nginx nginx-mod-http-dav-ext php7 php7-common php7-curl php7-json \
        php7-fpm php7-xml php7-mbstring php7-openssl php7-dom php7-exif php7-fileinfo \
        php7-pdo php7-phar php7-simplexml php7-tokenizer php7-xmlwriter php7-posix \
        php7-session php7-gd php7-opcache php7-pdo_mysql

# remove our APK cache
RUN rm -rf /var/cache/apk/*

# copy our dependant files
COPY resources/ /

# set permissions for our entrypoint
RUN chmod a+x /entrypoint.sh && \
    chown nobody:nobody /entrypoint.sh

# create our app directory
RUN mkdir /app && \
    echo "<?php phpinfo(); ?>" > /app/index.php && \
    chown -R nginx:www-data /app

# Configure PHP-FPM service
RUN	mkdir -p /run/php && \
#    ln -s /usr/bin/php7 /usr/bin/php && \
	chgrp -R www-data /run/php && \
	sed -i \
		-e "s/;daemonize = yes/daemonize = no/" \
		-e "s/;log_level = notice/log_level = warning/" \
		-e "s/;error_log = log\\/php7\\/error.log/error_log = syslog/" \
		/etc/php7/php-fpm.conf && \
	sed -i \
		-e "s/listen = 127.0.0.1:9000/listen = \\/run\\/php\\/php7.0-fpm.sock/" \
		-e "s/;listen.owner = nobody/listen.owner = nobody/" \
		-e "s/;listen.group = nobody/listen.group = www-data/" \
		-e "s/user = nobody/user = nginx/" \
		-e "s/group = nobody/group = www-data/" \
		-e "s/;clear_env = no/clear_env = no/" \
		/etc/php7/php-fpm.d/www.conf

# Configure nginx service
RUN	mkdir -p /run/nginx && \
    chgrp -R nginx /run/nginx && \
	mkdir -p /etc/nginx/sites-enabled && \
	rm -f /etc/nginx/conf.d/default.conf && \
	ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Expose nginx
EXPOSE 80 80

# start PHP-FPM
ENTRYPOINT "/entrypoint.sh"

# set our working directory to /app
WORKDIR /app