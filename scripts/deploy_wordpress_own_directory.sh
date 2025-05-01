#!/bin/bash

# Configuramos para mostrar los comandos y finalizar si hay error

set -ex

# Cogemos las variables.

source .env

# Descargamos la última versión de WordPress con el comando wget.

wget https://wordpress.org/latest.tar.gz -P /tmp

# Descomprimimos el archivo .tar.gz que acabamos de descargar con el comando tar.

tar -xzvf /tmp/latest.tar.gz -C /tmp

rm -rf /var/www/html/wordpress/

mkdir -p /var/www/html/wordpress/

# Ahora, movemos el contenido de /tpm/wordpress a /var/www/html.
mv -f /tmp/wordpress/* /var/www/html/wordpress/

# Creamos la base de datos y el usuario para WordPress.
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# Creamos un archivo wp-config.php a partir de uno de ejemplo.
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

# Configurar las variables de configuracion del archivo de wordpress.

sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wordpress/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wordpress/wp-config.php


# Configurar  las variables WP_SITEURL y WP_HOME

sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$CERTIFICATE_DOMAIN/wordpress');" /var/www/html/wordpress/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$CERTIFICATE_DOMAIN');" /var/www/html/wordpress/wp-config.php

# copiamos el archivo /var/www/html/wordpress/index.php a /var/www/html.
cp /var/www/html/wordpress/index.php /var/www/html


#Reemplazamos el contenido del archivo index.php

sed -i "s#wp-blog-header.php#wordpress/wp-blog-header.php#" /var/www/html/index.php 


# Ponemos el archivo htacess en /var/www/html/

cp ../htaccess/.htaccess /var/www/html

# Cambiamos el propietario y el grupo al directorio /var/www/html.

chown -R www-data:www-data /var/www/html/

# Habilitamos el módulo mod_rewrite de Apache.
a2enmod rewrite

# Después de habilitar el módulo deberá reiniciar el servicio de Apache.
sudo systemctl restart apache2

# Configuración de las security keys de WordPress
# ------------------------------------------------

# Borramos las security keys

sed -i "/AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/wordpress/wp-config.php


# Obtenemos las security keys y almacenamos el resultado en una variable de entorno.

SECURITY_KEYS=$(curl https://api.wordpress.org/secret-key/1.1/salt/)

# Para evitar posibles problemas con el carácter / vamos a reemplazarlo por el carácter _.

SECURITY_KEYS=$(echo $SECURITY_KEYS | tr / _)

# Añadimos las security keys al archivo de configuración.

sed -i "/@-/a $SECURITY_KEYS" /var/www/html/wordpress/wp-config.php

# Cambiamos el propietario y el grupo al directorio /var/www/html a www-data que es el que usa apache.

chown -R www-data:www-data /var/www/html/