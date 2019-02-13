# Deploy commands

## Nuxt Deploy


### Setup nuxt deploy commands

Setup your structure like this

```
- deploy-commands
- nuxt
---- pm2 ecosystem file
```

Where `nuxt` is just a folder to store your site releases, essentially. Not your repo!

Make a symbolic link to the nuxt-deploy folder:

`ln -s deploy-commands/nuxt-deploy nuxt/commands`

So that your structure now looks like:

```
- deploy-commands
- nuxt
---- pm2 ecosystem file
---- commands
```

Run your `pm2 start` based on your ecosystem file, which might look like this:

```
module.exports = {
  apps : [{
    name: 'NAME OF YOUR SERVER',
    cwd: './current/app', 
    script: './node_modules/nuxt/bin/nuxt-start',
    exec_mode: 'cluster',
    instances: '2',
    autorestart: true,
  }],
};
```

### Use nuxt deploy - build a release

Then go into your commands folder and

`./app-release -v=dev -r=git@github.com:you/yourrepo.git`

and answer questions - no this is not a tag release, no branch change needed.

This will:

- do a `git clone` of your repo, calling the folder `dev` inside your nuxt folder.
- attempts to `npm install` inside `dev/app` 
- attempts to `npm run build` inside `dev/app`

Structure should be like this:

```
- deploy-commands
- nuxt
---- pm2 ecosystem file
---- commands
---- dev
```

The `./app-release` file could be adjusted for where your package.json files are, since right now it's assuming `dev/app`.

### Use nuxt release - app-release

Run 

`./app-deploy -v=dev -s=nameofyourserver`;

This will:

- create a symbolic link named `current` that points to `dev`
- run the necessary `pm2 reload` on the server you specify

Now your structure is like this:

```
- deploy-commands
- nuxt
---- pm2 ecosystem file
---- commands
---- dev
---- current
```

Where current is a symbolic link to the latest release.

You can now continue to build more releases with `./app-release` based on tags perhaps, or different branches.

Then you can use `./app-deploy` to change which release is live - which is helpful for rolling back as well.