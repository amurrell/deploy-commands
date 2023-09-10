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

RELEASING_FROM=$(pwd)
ASSETS_FOLDER=$(<assetsfolder)

cd ../

APP_FOLDER=$(pwd)
RELEASES_FOLDER="$APP_FOLDER/releases"
CURRENT_FOLDER="$APP_FOLDER/current"
RELEASE_PATH="$RELEASES_FOLDER/$RELEASE"
ASSETS_PATH="$RELEASE_PATH/$ASSETS_FOLDER"

## Actually do the NPM things
printf "============ Second - Run the NPM things\n"

cd $ASSETS_PATH

npm install
npm run production

cd $RELEASING_FROM
