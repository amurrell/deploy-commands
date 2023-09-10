#!/usr/bin/env bash

set -e

TESTING_FROM=$(pwd)

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


# Run PM2 reload all
cd ../

# if there's an ecosystem.config.js file and pm2 is an available command, then run pm2 restart all
if [ -f "ecosystem.config.js" ] && [ -x "$(command -v pm2)" ]; then
    printf "============ ecosystem.config.js exists, so running pm2 restart all\n"
    pm2 restart all
fi

cd $TESTING_FROM

## Test nginx and php-fpm config
printf "============ Test nginx & php-fpm config\n"
sudo nginx -t && sudo php-fpm$PHP_VERSION -t
