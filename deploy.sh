#!/bin/bash

# exit asap if something fails
set -e

BRANCH='main'
TAG=''

# source .bashrc for node
printf "============ Source bash profile again to ensure node access\n"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source ~/.bashrc

# Display help information
display_help() {
    echo "Usage: $0 [OPTION]..."
    echo
    echo "Deploy a given repository."
    echo
    echo "Options:"
    echo "  --repo REPO_NAME    Specify the repository name follwing pattern: <username>/<project>"
    echo "  --branch BRANCH     Specify the branch name. eg. main, dev, staging"
    echo "  --tag TAG_NAME      Specify the tag name. eg. 1.0.0"
    echo "  --help              Display this help and exit."
    echo
    echo "You must provide at least the --repo option. Other options are optional."
    echo "For example: $0 --repo user/project --branch main"
}

# Get parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --repo) REPO="$2"; shift ;;
        --branch) BRANCH="$2"; shift ;;
        --tag) TAG="$2"; shift ;;
        --help) display_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; display_help; exit 1 ;;
    esac
    shift
done

# Check for mandatory parameters
if [[ -z "$REPO" ]]; then
    echo "Error: --repo is a mandatory parameter."
    display_help
    exit 1
fi

# Parse deploy.config.json using Node.js
getConfig() {
    # assumes the deploy.config.json is in the same location as deploy.sh (and typically at deploy user home directory.)
    echo "const data = require('deploy.config.json'); console.log(JSON.stringify(data['$REPO']));" | node
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
