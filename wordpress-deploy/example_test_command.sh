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

# if these folders exist: /var/nginx_cache and /var/ngx_pagespeed_cache
# then delete them and recreate them
if [ -d "/var/nginx_cache" ]; then
    printf "============ Delete and recreate /var/nginx_cache\n"
    sudo rm -rf /var/nginx_cache
    sudo mkdir /var/nginx_cache/
fi

if [ -d "/var/ngx_pagespeed_cache" ]; then
    printf "============ Delete and recreate /var/ngx_pagespeed_cache\n"
    sudo rm -rf /var/ngx_pagespeed_cache
    sudo mkdir /var/ngx_pagespeed_cache/
fi

## Test nginx and php-fpm config
printf "============ Test nginx & php-fpm config\n"
sudo nginx -t && sudo php-fpm$PHP_VERSION -t
