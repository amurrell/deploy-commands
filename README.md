# Deploy commands

## Install

Clone the repo, create symbolic link to commands folder you need.

Example: **Be sure to change** `{TYPE}` to match either `pm2` or `laravel`

```
cd /var/www/yoursite.com
git clone git@github.com:amurrell/deploy-commands.git
ln -s deploy-commands/{TYPE}-deploy ./commands
```

---

## Usage

The main actions are `releasing` and `deploying`.

- `Releasing` simply clones and/or checkout a branch/tag and runs build processing (eg. npm install && npm run build, composer install)
- `Deploying` simply takes a folder name (release) to change out the current live directory (via symbolic link) and/or reloads services

**Building a Release - Prompted Vs. Unprompted**

You can trigger the `app-release` either via prompted questions or provide switches.

- `./app-release`
- `./app-release -r=git@github.com:you/yourrepo.git -v=1.0.1 -t=true -b=false -a=true`

**Deploy ANY Release - Unprompted only**

You can choose any release folder to deploy, which is great for new releases and rolling back.

Trigger the `app-deploy` only through switches or get error messages. You will want to make sure the release and server values are accurate.

- `./app-deploy -v=1.0.1 -s=my-app-server`

---

## Setup Config Files

To help automate deployment processes, you can use these configuration files to avoid some repetitive prompts, eg. the app's repo to build from, or the pm2 server name

These are ignored by git and live inside the commands folder you created above.

Place your config files into the commands folder directly, like this:

#### .../commands
```
- app-deploy
- app-release
- [other possible commands]
- apprepo # a config file
```

### Generic Deploy-Commands Config

| File | Example Contents | Description |
|----|----|-----|
| apprepo | `git@github.com:you/yourrepo.git` | Optional - used to avoid being prompted every time |
| owner_user | `www-data`, `ubuntu` | Optional - default is `www-data` and is used with chown command on project files and the symbolic link live `current` folder<br>eg.<br>`sudo chown -R $OWNER_USER:$OWNER_GROUP "<folder>"`<br> or derived, <br>`sudo chown -R ubuntu:www-data /var/www/project/current` |
| owner_group | `www-data`, `ubuntu` | Optional - default is `www-data` and is used with chown command on project files and the symbolic link live `current` folder<br>eg.<br>`sudo chown -R $OWNER_USER:$OWNER_GROUP "<folder>"`<br> or derived, <br>`sudo chown -R ubuntu:www-data /var/www/project/current` |
| npm_command | `npm install && npm run build`,<br>`nvm use && npm install && npm run production` | Optional - default is `npm install && npm run build`. |


### PM2 Deploy-Commands Config

| File | Example Contents | Description |
|----|----|-----|
| appservername | `my-app-server` | Optional - the name of the server used in pm2, only needed to avoid being prompted everytime |
| appenvfile | `BASE_API_URL=https://someurl` | Optional - If you need to use a dotenv file with deploys on this server |
| npm_command | `npm install && npm run build`, `npm run production` | Optional - default is `npm install && npm run build`. |
| applogsfolder | `logs`, `DockerLocal/logs` | Optional - makes a directory `logs` by default, but nothing else happens - useful to create this directory for pointing php/nginx log files to

The **appservername** should correlate to your ecosystem file, if you are using one with pm2. 

#### Ecosystem

Create a file `ecosystem.config.js` similar to below and place it in the same level as your `commands` folder

```
module.exports = {
  apps : [{
    name: 'NAME OF YOUR SERVER',
    cwd: './current/app', 
    script: './node_modules/nuxt-start/bin/nuxt-start.js',
    exec_mode: 'cluster',
    instances: '2',
    autorestart: true,
    log_date_format: "MM/DD/YYYY HH:mm:ss",
    args: "start"
  }],
};
```

Where your directory structure might look like:
```
- yoursite.com
----- deploy-commands
----- commands      # symbolic link to deploy-commands/pm2-deploy
----- releases
  ----- 1.0.0         # release on tag
  ----- 1.0.1         # release on tag
  ----- dev           # release on branch
----- ecosystem.config.js
```

Ensure that the "NAME OF YOUR SERVER" matches the appservername config or the `-s` switch in the release/deploy/pm2-deploy/commands

From that folder, run your `pm2 start`

### Laravel Deploy-Commands Config

| File | Example Contents | Description |
|----|----|-----|
| laravelfolder | `laravel-app` | Optional - only needed if laravel is in a subfolder of your repo eg. `yourrepo/laravel-app` |
| assetsfolder | `laravel-app/resources/vue` | Optional - if you have frontend assets to build - this is the directory location of your package.json in your repo. eg `yourrepo/laravel-app/resources/vue` or `yourrepo/resources/vue` |
| assetsenvfile | {.env file} | Optional - will get copied into your assetsfolder (relative to package.json) |
| laravelenvfile | {typical laravel .env file} | Optional - will get copied into your release |
| laravellogsfolder | `logs`, `DockerLocal/logs` | Optional - makes a directory `logs` by default, but nothing else happens - useful to create this directory for pointing php/nginx log files to

Laravel deployments uses **a releases folder** such that the directory structure looks like this:

```
- yoursite.com
----- deploy-commands
----- commands           # symbolic link to deploy-commands/laravel-deploy
----- releases
---------- 1.0.0         # release on tag
---------- 1.0.1         # release on tag
---------- dev           # release on branch
```