#!/bin/bash

# Configuramos para mostrar los comandos y finalizar si hay error
set -ex

# Importamos el archivo de variables
source .env


# Instalamos y actualizamos snap
snap install core
snap refresh core

# Eliminamos instalaciones previas de cerbot 
apt remove certbot -y

# Instalamos Certbot
snap install --classic certbot

# Solicitamos un cerficado a Lets Encrypt
sudo certbot --apache -m $LE_EMAIL --agree-tos --no-eff-email -d $LE_DOMAIN --non-interactive