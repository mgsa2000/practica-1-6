# practica-1-6

En esta practica vamos a realizar una instalacion de Wordpress en una instancia de amazon.
Como ya sabemos,estas prácticas son evoluciones de las nteriores,con esto me refiero, a que usaremos el script de la pila lamp,el archivo de variables.
Aparte,usaremos un .htaccess para configurar los enlaces permanentes de wordpress.
Usaremos nuestro dominio creado de la practica anterior.

## 1. Instalación de la pila lamp.
Como ya sabesmos,nuestro script tiene lo siguiente:
```bash
set -ex
```
Actualizamos repositorios y paquetes.
```bash
apt update
apt upgrade -y
```

Instalamos apache y habilitamos el modulo de reescritura.
```bash
apt install apache2 -y
a2enmod rewrite
```
Copiamos el archivo de conf en sitios disponibles.
```bash
cp ../conf/000-default.conf /etc/apache2/sites-available
```
Instalamos PHP.

```bash
apt install php libapache2-mod-php php-mysql -y
```
Reiniciamos apache.

```bash
systemctl restart apache2
```

Ahora instalamos MySQL

```bash
apt install mysql-server -y
```

Copiamos el script de prueba de PHP en /var/www/html y cambiamos el propietario para que sesa apache.

```bash
cp ../php/index.php /var/www/html
chown -R www-data:www-data /var/www/html
```
## 2.Instalación del certificado de lets encrypt

Con este script tendremos un certificado seguro.

Comando para ver cada comando y finalizar si hay error.

```bash
set -ex
```
Importamos el archivo de variables

```bash
source .env
```

Instalamos y actualizamos snap

```bash
snap install core
snap refresh core
```

Eliminamos instalaciones previas de cerbot con apt

```bash
apt remove certbot -y
```

Instalamos Certbot

```bash
snap install --classic certbot
```

Solicitamos un cerficado a Let`s Encrypt. Las variables de este comando tiene que ser el email que queramos y el dominio que hemos creado a traves de no-ip.

```bash
sudo certbot --apache -m $LE_EMAIL --agree-tos --no-eff-email -d $LE_DOMAIN --non-interactive
```

## 3.Instalación de wordpress

En esta practica hemos realizado 2 script de instalacion de wordpress,muy similares,la diferencia es que uno es en su propio directorio mientras que el otro es en el directorio raíz.Nosotros,vamos a realizar el de su directorio propio.Para ello lanzareemos este el script
script deploy_wordpress_own_directory.sh.
Configuramos para mostrar los comandos y finalizar si hay error

```bash
set -ex
```

Cogemos las variables de nuestro archivo env.

```bash
source .env
```

Descargamos la última versión de WordPress con el comando wget.

```bash
wget https://wordpress.org/latest.tar.gz -P /tmp
```

Descomprimimos el archivo .tar.gz que acabamos de descargar con el comando tar


```bash
tar -xzvf /tmp/latest.tar.gz -C /tmp
```

Ahora, movemos el contenido de /tpm/wordpress a /var/www/html/wordpress/.

```bash
mv -f /tmp/wordpress/* /var/www/html/wordpress/
```

Creamos la base de datos y el usuario para WordPress. El valor de la variable $IP_CLIENTE_MYSQL tiene que ser localhost.

```bash
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
```

Creamos un archivo wp-config.php a partir de uno de ejemplo.

```bash
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
```

Configuramos las variables de configuracion del archivo de wordpress a traves del comando sed -i con las variables que hemos usado antes en la creacion de mysql y que estan en .env

```bash
sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wordpress/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wordpress/wp-config.php
```

Cuando se realiza una instalacion en el propio directorio se tienen que Configurar las variables WP_SITEURL(la url donde esta instalado) y WP_HOME(la url para que accedamos)

```bash
sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$CERTIFICATE_DOMAIN/wordpress');" /var/www/html/wordpress/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$CERTIFICATE_DOMAIN');" /var/www/html/wordpress/wp-config.php
```

Copiamos el archivo /var/www/html/wordpress/index.php a /var/www/html.

```bash
cp /var/www/html/wordpress/index.php /var/www/html
```

Reemplazamos el contenido del archivo index.php

```bash
sed -i "s#wp-blog-header.php#wordpress/wp-blog-header.php#" /var/www/html/index.php 
```

Ponemos el archivo htacess en /var/www/html/ que hemos creado con anterioridad para redirigir todas las peticiones a index.php

```bash
cp ../htaccess/.htaccess /var/www/html
```

Cambiamos el propietario y el grupo al directorio /var/www/html.

```bash

chown -R www-data:www-data /var/www/html/
```
Habilitamos el módulo rewrite de Apache.

```bash
a2enmod rewrite
```

Después de habilitar el módulo reiniciamos el servicio de Apache.

```bash
sudo systemctl restart apache2
```

```bash
sed -i "/AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/wordpress/wp-config.php
```

Obtenemos las security keys a traves de una API y las guardamos en una variable.

```bash
SECURITY_KEYS=$(curl https://api.wordpress.org/secret-key/1.1/salt/)
```

A veces al darnos una claves seguras podemos tener problemas con el carácter / , para ello vamos a reemplazarlo por el carácter _

```bash
SECURITY_KEYS=$(echo $SECURITY_KEYS | tr / _)
```

Añadimos las security keys que hemos obtenido al archivo de configuración.

```bash
sed -i "/@-/a $SECURITY_KEYS" /var/www/html/wordpress/wp-config.php
```

Por ultimo cambiamos el propietario y el grupo al directorio /var/www/html.
```bash
chown -R www-data:www-data /var/www/html/
```

## 4.Comprobaciones

