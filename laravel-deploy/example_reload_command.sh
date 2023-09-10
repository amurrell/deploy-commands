#!/usr/bin/env bash

set -e

# if /var/www/LEMP-setup-guide exists
if [ -d "/var/www/LEMP-setup-guide" ]; then
  PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/php-version)
  # if override-php-version is set, use that
  if [ -f "/var/www/LEMP-setup-guide/config/versions/override-php-version" ]; then
      PHP_VERSION=$(cat /var/www/LEMP-setup-guide/config/versions/override-php-version)
  fi
else
  PHP_VERSION=8.2
fi

# Reload
printf "============ Reloading nginx and php-fpm\n"
sudo service nginx reload && sudo service php$PHP_VERSION-fpm reload
