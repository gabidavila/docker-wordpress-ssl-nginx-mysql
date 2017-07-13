#!/usr/bin/env bash

# ===============================================================================
# Bash Script - Init
#
# The task includes:
#
# - Set up **default** env. variables, such as **DB host name**, **DB access info**, etc.
# - Modify the `wp-config.php` based on the **env. variables**.
# - Update **Server Name** to all other config files.
# - Start supervisord service.
#
# ===============================================================================


# ===============================================================================
# Env. Variables
#
# For **DB variables**, although they can be retrieved from **ENV. variables exposure**
# under **version 1**, it still recommended to be specified separately.
#

# ----------------------------------------------------------
# Server Related
# Default: `example.com`
# ----------------------------------------------------------

SERVER_NAME=${SERVER_NAME:-example.com}

# ----------------------------------------------------------
# DB Related
# Default: The **exposed ENV. variables** from DB server.
# The prefix "DB" is just the "alias" of the DB server.
# ----------------------------------------------------------

#mysql has to be started this way as it doesn't work to call from /etc/init.d
/usr/bin/mysqld_safe &
sleep 10s

WP_DATABASE="wordpress"
DB_PASSWORD=`pwgen -c -n -1 12`
WP_PASSWORD=`pwgen -c -n -1 12`
echo $DB_PASSWORD > /mysql-root-pw.txt
echo $WP_PASSWORD > /wordpress-db-pw.txt

# ===============================================================================
# Modify `wp-config.php` File
#
# Need to do swap on the following parts
#
#   // ** MySQL settings - You can get this info from your web host ** //
#   /** The name of the database for WordPress */
#   define( 'DB_NAME', 'database_name_here' );
#
#   /** MySQL database username */
#   define( 'DB_USER', 'username_here' );
#
#   /** MySQL database password */
#   define( 'DB_PASSWORD', 'password_here' );
#
#   /** MySQL hostname */
#   define( 'DB_HOST', 'localhost' );
#
#   ....
#
#   define( 'AUTH_KEY',         'put your unique phrase here' );
#   define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
#   define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
#   define( 'NONCE_KEY',        'put your unique phrase here' );
#   define( 'AUTH_SALT',        'put your unique phrase here' );
#   define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
#   define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
#   define( 'NONCE_SALT',       'put your unique phrase here' );
#
#
#  For all the other keys, we will use `pwgen` (Open-Source Password Generator)
#   to help generate random string.

# Backup the `config` file if it exists.
# `/usr/share/nginx/www/` is the **webroot**.
if [ -f /usr/share/nginx/www/wp-config.php ]; then
  cp /usr/share/nginx/www/wp-config.php /usr/share/nginx/www/wp-config.php.orig
fi

# Search and replace the **string**.
sed -e "s/database_name_here/$WP_DATABASE/
s/username_here/$WP_DATABASE/
s/password_here/$WP_PASSWORD/
/'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" \
/usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

# Change `user:group` for `wp-config.php`.
chown www-data:www-data /usr/share/nginx/www/wp-config.php

mysqladmin -u root password $DB_PASSWORD
  mysql -uroot -p$DB_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  mysql -uroot -p$DB_PASSWORD -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WP_PASSWORD'; FLUSH PRIVILEGES;"
  killall mysqld

# ===============================================================================
# Update `HOST_NAME` to other places
#

# Replace the placeholder in Nginx config files for server name.
sed -i -e "s/server_name_placeholder/$SERVER_NAME/g" /etc/nginx/nginx-site-http.conf
sed -i -e "s/server_name_placeholder/$SERVER_NAME/g" /etc/nginx/nginx-site-https.conf
sed -i -e "s/server_name_placeholder/$SERVER_NAME/g" /etc/nginx/sites-available/default

# add server name to /etc/hosts to avoid timeout when code make http call to public url
EXT_IP=`ip route get 8.8.8.8 | awk '{print $NF; exit}'`
echo "$EXT_IP   $SERVER_NAME" >> /etc/hosts

# we want to be able to curl the web site from the localhost using https (for purging the cache, and for the cron)
echo "127.0.0.1 $SERVER_NAME" >> /etc/hosts



# ===============================================================================
# Start all the **supervisord** services
#

/usr/local/bin/supervisord -n
