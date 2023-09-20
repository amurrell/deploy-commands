# Deploy commands

Deploying applications can be streamlined using a set of commands. These commands facilitate various actions like releasing and deploying your application. Depending on the type of your application (e.g., Node, Laravel, WordPress), you can use the appropriate command set.

## Install

Navigate to the required directory and clone the repository. After cloning, create a symbolic link to the desired command folder:

```
cd /var/www/yoursite.com
git clone git@github.com:amurrell/deploy-commands.git
ln -s deploy-commands/{TYPE}-deploy ./commands
```

Clone the repo, create symbolic link to commands folder you need.

> [!IMPORTANT]
> **Be sure to change** `{TYPE}` to match either `pm2` (eg. node projects), `laravel` or `wordpress`.


[Add configuration files](#setup-config-files) for skipping prompts and better automation by adding files to your commands folder, see below:

- [Generic - all {type}s](#generic-deploy-commands-config)
- [PM2](#pm2-deploy-commands-config)
- [Laravel](#laravel-deploy-commands-config)
- [Wordpress](#wordpress-deploy-commands-config)


**Automated Deployments via Github Workflow**

For more information about this, skip to the section below: [Automated Deployments via Github Workflow](#automated-deployments-via-github-workflow)

[↑ Top](#install)

---

## Usage

Our deployment system is designed around two main actions: `releasing` and `deploying`.

**Releasing**: This refers to the action where the system clones the desired repository into `releases` folder and/or checks out a specified branch or tag. Post-checkout, it manages build tasks, such as executing `npm install && npm run build` or `composer install`.

**Deploying**: This action replaces the current live directory with a symbolic link `current` pointing to the selected release. It might also run a custom test-command and upon success a reload-command associated services if required - eg. `sudo nginx -t` and `sudo service nginx reload`, respectively.

#### Building a Release - Prompted Vs. Unprompted

You can initiate `app-release` in two different ways:

1. **Prompted** By simply running the command without parameters, the system will ask you a series of questions to guide the release process.

    ```
    ./app-release
    ```

2. **Unprompted** You can also run the command with parameters to avoid the prompts. This is useful for automation.

    ```
    ./app-release -r=git@github.com:you/yourrepo.git -v=1.0.1 -t=true -b=false -a=true
    ```

    | Switch | Description |
    |----|----|
    | -r | Repository URL to clone. This can be omitted if apprepo config file exists. |
    | -v | Specifies the version to checkout. This can be a text label or a tag number. |
    | -t | Indicates if you're using a tag. Accepts `true` or `false`. |
    | -b | If you want to specify a branch to checkout, provide its name; else, use false.  |
    | -a | Exclusive to `laravel-deploy`. Determines if the assets directory should be built during release using `./build-assets`. |

#### Deploy ANY Release - Unprompted only

For deployment, you'll need to specify a release folder. This is handy for pushing new versions as well as reverting to prior ones. Deployment commands are always unprompted:

```
./app-deploy -v=1.0.1 -s=my-app-server
```

| Switch | Description |
|----|----|
| -v | Version to deploy; required - can be text or a tag number |
| -s | The server name (required for PM2). If `appservername` config file is present, this can be omitted.|

**Note:** During the deployment, the system will run the `test_command`. If tests pass, the `reload_command` will be executed, provided these commands are present in your commands directory.

[↑ Top](#install)

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
| test_command | `./test_command.sh` | Optional - The presence of this file will ensure it happens and only with successful exit will it run reload_command.<br>Purposely, it calls another command so that the exit status and "work" can be based on the script it calls. Useful for testing configuration eg. nginx -t |
| test_command.sh | `sudo nginx -t`, <br>`sudo php$PHP_VERSION-fpm -t` | Optional - copy from example for ideas. |
| reload_command | `./reload_command.sh` | Optional - only ran if test_command was successful. Useful for reloading nginx |
| reload_command.sh | `sudo service nginx reload`, <br> `sudo service nginx reload && sudo service php-fpm$PHP_VERSION restart` | Optional - copy from example for ideas. |
| npm_command | `./npm_command.sh`,<br>`nvm use && npm install && npm run production` | Optional - default is `npm install && npm run build`. |
| npm_command.sh | `npm install && npm run build`,<br>`nvm use && npm install && npm run production` | Optional - copy from example for ideas. |

[↑ Top](#install)

---

### PM2 Deploy-Commands Config

| File | Example Contents | Description |
|----|----|-----|
| appfolder | `app` | Optional - Your package.json and .env file should be here, relative to repo root. Only needed if your app is in a subfolder of your repo eg. `yourrepo/app` |
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

[↑ Top](#install)

---

### Laravel Deploy-Commands Config

| File | Example Contents | Description |
|----|----|-----|
| laravelfolder | `laravel-app` | Optional - only needed if laravel is in a subfolder of your repo eg. `yourrepo/laravel-app` |
| assetsfolder | `laravel-app/resources/vue` | Optional - if you have frontend assets to build - this is the directory location of your package.json in your repo. eg `yourrepo/laravel-app/resources/vue` or `yourrepo/resources/vue`. The presence of this path will auto build assets folder unless passing -a=false to app-release. |
| assetsenvfile | {.env file} | Optional - will get copied into your assetsfolder (relative to package.json) |
| laravelenvfile | {typical laravel .env file} | Optional - will get copied into your release |
| laravellogsfolder | `logs`, `DockerLocal/logs` | Optional - makes a directory `logs` by default, but nothing else happens - useful to create this directory for pointing php/nginx log files to

Laravel deployments uses **a releases folder** such that the directory structure looks like this:

```
- yoursite.com
----- deploy-commands
----- commands              # symbolic link to deploy-commands/laravel-deploy
----- ecosystem.config.js   # optional, eg. if using for horizon
----- releases
---------- 1.0.0            # release on tag
---------- 1.0.1            # release on tag
---------- dev              # release on branch
```

#### Ecosystem file for horizon in laravel

You might also have an ecosystem.config.js file here for pm2 to run horizon

```
{
  name: 'laravel-horizon',
  cwd: './current/app',
  interpreter: 'php',
  script_path: '/var/www/current/app/artisan',
  script: 'artisan',
  args: 'horizon',
  instances: 1,
  autorestart: true,
  watch: false,
  max_memory_restart: '1G',
  merge_logs: true,
  out_file: "/var/www/yoursite.com/current/DockerLocal/logs/horizon.log",
  error_file: "/var/www/yoursite.com/current/DockerLocal/logs/horizon.log",
  log_date_format: "MM/DD/YYYY HH:mm:ss",
}
```

[↑ Top](#install)

---

### Wordpress Deploy-Commands Config

You could use this for any php project, but a common use case is wordpress.
If the uploads folder is present in the below directory structure, each release's wordpress uploads path will symlink to it.

| File | Example Contents | Description |
|----|----|-----|
| assetsfolder | `html/wp-content/themes/<yourtheme>/` | Optional - if you have frontend assets to build - this is the directory location of your package.json in your repo. |
| logsfolder | `logs`, `DockerLocal/logs` | Optional - makes a directory `logs` by default, but nothing else happens - useful to create this directory for pointing php/nginx log files to

Wordpress deployments uses **a releases folder** such that the directory structure looks like this:

```
- yoursite.com
----- deploy-commands
----- commands           # symbolic link to deploy-commands/wordpress-deploy
----- uploads            # uploads folder in releases will symlink to this
----- releases
---------- 1.0.0         # release on tag
---------- 1.0.1         # release on tag
---------- dev           # release on branch
```

[↑ Top](#install)

---

## Automated Deployments via Github Workflow

Follow these steps to set up a deployment process via github workflows for your project:

1. **Integrate Workflow File & Setup Key Pairs**

    Copy the `deploy-workflow.yml` into your site's repository under the `.github/workflows/` directory:

    ```bash
    cp deploy-workflow.yml /path/to/your/site/repo/.github/workflows/deploy.yml
    ```

    Ensure you save secrets to your repository for the following:

    - SERVER_ADDRESS
    - SERVER_SSH_KEY (private key)
    - DEPLOY_USER

    And store the public key of your server in the `authorized_keys` file of the deployment user. eg. /home/ubuntu/.ssh/authorized_keys

    _If you have this repo on different servers, you'd want to add to this workflow file to do some routing - eg. "if the branch is main or a tag release, deploy to production server, else deploy to dev server" and that would mean setting up more secrets - eg. `PROD_SERVER_ADDRESS`_

2. **Create a Deploy Script on Server**

    Copy the `deploy.sh` script to the home directory of the deployment user on your server:

    ```bash
    scp deploy.sh user@your.server.ip:~/
    ```

3. **Create Configuration File**

    On the server, in the home directory of the deployment user, create a configuration file named `deploy.config.json`. It should match the following structure:

    ```json
    {
      "<user>/<repo-name>": {
        "<env>": {
          "commands": "/var/www/<domain>/commands",
          "releases": "/var/www/<domain>/releases"
        }
      }
    }
    ```

    _If your server has only 1 env setting, it will not do any branch/tag related checks to decide which `/var/www/<folder>` to deploy to. This is useful if you handled that in the workflow file instead, eg the environments are spread across different servers._

- `<env>` can have values like `prod` which maps to domain structures like `www.site.com` or `site.com`.
- Any subdomain, like dev.site.com, would have an `<env>` value of `dev`.

The structure relies on the `deploy-commands` file structure convention:

- `/var/www/<domain>/deploy-commands`
- `/var/www/<domain>/releases`
- `/var/www/<domain>/current` (this should be a symlink pointing to a specific version in the releases directory)

### Generate Config File Automatically

If you'd prefer to automate the creation of the `deploy.config.json` file, you can fetch our pre-made script:

```bash
curl https://github.com/amurrell/SimpleDocker/scripts/templates/070-deploy-config-RAOU.sh -o generate-deploy-config.sh
chmod +x generate-deploy-config.sh
./generate-deploy-config.sh
```

This script will inspect the `/var/www/` directory on your server, identify domain folders that contain `deploy-commands` repo, and generate the `deploy.config.json` file accordingly.

[↑ Top](#install)
