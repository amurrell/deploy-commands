#!/bin/bash

# Get parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --repo) REPO="$2"; shift ;;
        --branch) BRANCH="$2"; shift ;;
        --tag) TAG="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Parse deploy.config.json using Node.js
getConfig() {
    echo "const data = require('/path/to/deploy.config.json'); console.log(JSON.stringify(data['$REPO']));" | node
}

CONFIG=$(getConfig)

# Check if only one environment is present
if [ $(echo "$CONFIG" | node -e "let input = ''; process.stdin.on('data', data => { input += data; }).on('end', () => { let envs = Object.keys(JSON.parse(input)); console.log(envs.length); });") -eq 1 ]; then
    ENV=$(echo "$CONFIG" | node -e "let input = ''; process.stdin.on('data', data => { input += data; }).on('end', () => { let envs = Object.keys(JSON.parse(input)); console.log(envs[0]); });")
else
    # Determine environment based on branch or tag
    case $BRANCH in
        main|master)
            ENV="prod"
            ;;
        dev)
            ENV="dev"
            ;;
        staging)
            ENV="staging"
            ;;
        *)
            # If it's a tag release and prod exists
            if [ ! -z "$TAG" ]; then
                ENV="prod"
            else
                echo "No suitable environment found for the branch/release."
                exit 1
            fi
            ;;
    esac
fi

# Extract releases and commands path from the chosen environment
RELEASES_PATH=$(echo "$CONFIG" | node -e "let input = ''; process.stdin.on('data', data => { input += data; }).on('end', () => { let data = JSON.parse(input); console.log(data['$ENV'].releases); });")
COMMANDS_PATH=$(echo "$CONFIG" | node -e "let input = ''; process.stdin.on('data', data => { input += data; }).on('end', () => { let data = JSON.parse(input); console.log(data['$ENV'].commands); });")

# Set version and type (tag or branch)
if [[ -n "$TAG" ]]; then
    VERSION=$TAG
    TYPE=true
else
    VERSION="$BRANCH-$(date +%Y%m%d%H%M%S)"
    TYPE=false
fi

# Navigate to commands path and execute deployment scripts
cd $COMMANDS_PATH

# If release goes well, then deploy.
if ./app-release -v=$VERSION -t=$TYPE -b=$BRANCH; then
    # If deploy goes well, then delete old releases (and not this one)
    if ./app-deploy -v=$VERSION; then
        # Go up one layer to "domain"
        cd ../

        # Get pwd
        PWD=$(pwd)
        DOMAIN=$(basename $PWD)

        # Get the target of the symbolic link
        CURRENT_RELEASE=$(readlink /var/www/$DOMAIN/current)

        cd $RELEASES_PATH

        # List all folders except the current release and the most recent one, then delete them
        for FOLDER in $(ls -tp | grep '/$' | grep -v "^$(basename $CURRENT_RELEASE)/" | tail -n +2); do
            rm -rf "$FOLDER"
        done
    fi
fi
