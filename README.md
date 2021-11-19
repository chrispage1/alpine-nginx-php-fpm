# Alpine nginx php-fpm

Project to run Laravel applications on a dockerised environment. Bundles php-fpm (8.1) & nginx together to create a quick and easy experience.

## Optimisation

By default we've optimised nginx & php-fpm ready to be run on a production environment.

## PHP Packages

PHP packages include redis, pcntl, exif, gd, pdo_mysql & opcache as standard. Additional packages can easily be installed
using the pre-installed package [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer).

This simple package allows you to quickly install additional PHP packages by running `install-php-extensions package_name`.
For a list of supported extensions, check the [support extensions graph](https://github.com/mlocati/docker-php-extension-installer/tree/1.2.15#supported-php-extensions).

## Opcache

This package is meant for production grade performance. As such the PHP files shouldn't change.
The default settings ignore timestamp validation to squeeze every bit of performance possible.
To change this, you can add your own build file with - 

`RUN sed -i 's|opcache.validate_timestamps=0|opcache.validate_timestamps=1|' "/usr/local/etc/php/conf.d/docker-php-ext-opcache.ini"`

## Health checks

The project has a php-fpm healthcheck service built in from [Renatomefi php-fpm-healthcheck](https://github.com/renatomefi/php-fpm-healthcheck).
It's up to you if you run this but it's recommended within production environments to ensure PHP-FPM hasn't become backlogged or died.

The health check can be performed by running `php-fpm-healthcheck` which returns a simple status code.
For more information, view Renatomefi's package using the link above.