#!/bin/bash

# Variables requeridas
# $repoApi = Repositorio que contiene el código de la api a desplegar
# $apiName = Nombre del proyecto o api

# Cargar variables de entorno
set -e

fetchApi(){
    # Desactiva verificación de certificados
    git config --global http.sslverify false

    cd /
    git clone $repoApi
    cd /$apiName

    cp /root/setup/.env ./ && cp /root/setup/ldap-client.ts ./src/config/
}

buildApi(){
    # Instalación de dependencias 
    npm i && npm run build
}

deployApi(){
    npm i -g pm2
    pm2 start dist/main.js --name "adt-backend"
}

main(){
    fetchApi
    buildApi
    deployApi
    tail -f /dev/null
}

main