FROM alpine:edge

# install packages
RUN apk update && \
    apk --no-cache add nginx nginx-mod-http-dav-ext php8 php8-common php8-curl php8-json php8-fpm php8-posix

# remove our APK cache
RUN rm -rf /var/cache/apk/*

# copy our dependant files
COPY resources/ /

# Configure PHP-FPM service
RUN	mkdir -p /etc/service && \
    mkdir -p /run/php && \
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
		/etc/php8/php-fpm.d/www.conf && \
	    chmod 755 /etc/services/php-fpm/run && \
	    ln -sf /etc/services/php-fpm /etc/service/

# Configure nginx service
RUN	sed -i '/^worker_processes auto;/a include /etc/nginx/modules/*.conf;' /etc/nginx/nginx.conf && \
	mkdir -p /var/www && \
	chown -R nginx:www-data /var/www && \
	rm -rf /var/www/localhost && \
	mkdir -p /etc/nginx/sites-available && \
	mkdir -p /etc/nginx/sites-enabled && \
	rm -f /etc/nginx/conf.d/default.conf && \
	ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/ && \
	chmod 755 /etc/services/nginx/run && \
	ln -sf /etc/services/nginx /etc/service/
