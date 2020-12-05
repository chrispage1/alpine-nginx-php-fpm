FROM alpine:edge

# install packages
RUN apk update && \
    apk --no-cache add runit nginx nginx-mod-http-dav-ext php8 php8-common php8-curl php8-json php8-fpm php8-posix

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
	chgrp -R www-data /run/php && \
	sed -i \
		-e "s/;daemonize = yes/daemonize = no/" \
		-e "s/;log_level = notice/log_level = warning/" \
		-e "s/;error_log = log\\/php8\\/error.log/error_log = syslog/" \
		/etc/php8/php-fpm.conf && \
	sed -i \
		-e "s/listen = 127.0.0.1:9000/listen = \\/run\\/php\\/php8.0-fpm.sock/" \
		-e "s/;listen.owner = nobody/listen.owner = nobody/" \
		-e "s/;listen.group = nobody/listen.group = www-data/" \
		-e "s/user = nobody/user = nginx/" \
		-e "s/group = nobody/group = www-data/" \
		-e "s/;clear_env = no/clear_env = no/" \
		/etc/php8/php-fpm.d/www.conf

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