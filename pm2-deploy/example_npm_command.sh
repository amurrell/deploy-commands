#!/usr/bin/env bash

V=$(sed -e 's#.*\-v=\([^[:space:]]*\?\).*#\1#' <<< "$*")

# if $RELEASE is empty, then check $V
if [ -z "$RELEASE" ]; then
    if [ "$V" == "$*" ]; then
        read -p "Release Name - eg 1.0.1: " RELEASE
    else
        RELEASE=$V
    fi
fi

cd $CURRENT

printf "============ Source bash profile again to ensure pm2 and nvm access\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source ~/.bashrc

# Change release-based environmental vars - example: BUGSNAG_VERSION=1.0.1
sed -i "s/BUGSNAG_VERSION=.*/BUGSNAG_VERSION=$RELEASE/" .env

nvm use && npm install && npm run build
