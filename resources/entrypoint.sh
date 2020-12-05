#!/bin/sh

# start php-fpm in daemon mode
/usr/sbin/php-fpm7 --pid /run/php/php-fpm.pid -D

if [ $? -ne 0 ]; then
  echo "Failed to start php-fpm: $status"
  exit $?
fi

# wait for php-fpm to become available
while true; do
    ps aux | grep "php-fpm: master process" | grep -q -v grep
    if [ $? -eq 0 ]; then
      break;
    fi

    sleep 1
done

/usr/sbin/nginx &

if [ $? -ne 0 ]; then
  echo "Failed to start nginx: $status"
  exit $?
fi

while sleep 10; do

  ps aux | grep "nginx: master process" | grep -q -v grep
  NGINX_STATS=$?

  ps aux | grep "php-fpm: master process" | grep -q -v grep
  PHP_FPM_STATUS=$?

  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $NGINX_STATS -ne 0 -o $PHP_FPM_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done