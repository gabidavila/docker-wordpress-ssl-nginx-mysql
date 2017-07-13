# All in one Wordpress Dockerfile: Wordpress + Nginx + MySQL + SSL

[![](https://badge.imagelayers.io/snapturtle/docker-wordpress-ssl-nginx-mysql:latest.svg)](https://imagelayers.io/?images=snapturtle/docker-wordpress-ssl-nginx-mysql:latest 'Get your own badge on imagelayers.io')

Forked from ([https://github.com/cowfox/docker-wordpress-nginx-fpm-cache-ssl](https://github.com/cowfox/docker-wordpress-nginx-fpm-cache-ssl)). Added local MySQL to Dockerfile and config for an all in one solution.

Docker file with related **scripts** and **config** files to help build a Docker container that runs the following pieces **out-of-the-box**:

- PHP-FPM.
- Nginx with `fastcgi-cache` and `fastcgi_cache_purge`.
- Opcache.
- MySQL
- Wordpress with the **latest** version. 

Also, it provides the following **optional** scripts:

- Add **existing** SSL cert files into Nginx config. 
- Auto-generate SSL cert and add into Nginx config. It is done through **letsencrypt** ([https://letsencrypt.org/](https://letsencrypt.org/))
- Auto-download a pre-defined list of Wordpress plugins. 

## Usage

The docker image comes with the default **CMD script** - `init.sh`, which mainly does: 

- Set up **default** env. variables, such as **DB host name**, **DB access info**, etc.
- Modify the `wp-config.php` based on the **env. variables**.
- Update **Server Name** to all other config files.
- Start [supervisord](http://supervisord.org/) service. 

It takes five **env. variables**: 

- `SERVER_NAME` - the server name that serves the Wordpress. 
- `DB_DATABASE` - the local MySQL database name 
- `DB_PASSWORD` - the root Mysql password 
- `WP_PASSWORD` - the password of the Mysql username that accesses to the database. 

If using `docker run` CMD to build the container, be sure to use `--env` to add these variables. 

### Docker Compose

When using `docker compose` config file `docker-compose.yml` to build the containers, it would be much simpler. If using `link` between **wordpress** and **mysql** containers, the `init.sh` script can automatically get the **DB access info** by using the **[link environment variables](https://docs.docker.com/compose/link-env-deprecated/)**. 

> Seems that `link` can only work with **version 1** of docker compose config file. 

The docker compose config file would be like this. 

```
wordpress:
  image: snapturtle/docker-wordpress-ssl-nginx-mysql
  environment:
    SERVER_NAME: "example.com"
  ports:
    - "80:80"
    - "443:443"
```

> Please note: when linking the mysql DB, be sure to assign it with an alias **db**, since `init.sh` script uses it to load the **link environment variables**. 


## Optional Scripts

When container being built, all the **three** optional scripts will be copied to `/addon/` folder inside the container. 

- `/addon/wp-install-plugins.sh` - It helps download a **pre-defined** list of Wordpress plugins, in the variable `PLUGINS`. By default, it only has `nginx-helper` in the list. When using this script, it is recommended to modify this script (you can grab it from Github) and then **mount** it back to the container when building it. 
- `/addon/ssl.sh` - It helps add **existing** SSL cert file to Nginx config. The script uses there **ENV. variables**. 
	- `SSL_TRUSTED_CERT_FILE` - The **file path** to the **trusted cert file**. The path must be **inside** the container. 
	- `SSL_CERT_FILE` - The **file path** to the **cert file**. 
	- `SSL_CERT_KEY_FILE` - The **file path** to the **private key file**. 
- `/addon/letsencrypt/ssl-letsencrypt.sh` - It help auto-generate the `letsencrypt` SSL cert and add to Nginx config. The script uses there **ENV. variables**. 
	- `LE_WEBROOT` - The **web root** that `letsencrypt` uses. By default, it is `/tmp/letsencrypt-auto`. 
	- `LE_INI_FILE` - The **file path** to the **ini** files that used to generate the SSL cert. By default, it is `/letsencrypt-le.ini`. 
	- `LE_ACME_FILE` - The **file path** to the **location block of ACME Challenge** that `letsencrypt` uses. By default, it is `/nginx-acme.challenge.le.conf`. 
	
For the file `letsencrypt-le.ini` and `nginx-acme.challenge.le.conf`, you can check the Github repo (`/config/addon/`) for example. 


## Customize it

Besides the above scripts and sample files, Github repo also ships with the **config** files that Nginx uses, like `nginx.conf`, site config, SSL config, etc. If needed to modify them, just `git clone` from Github, modify them and then do docker image build on your side. 

## License

MIT

