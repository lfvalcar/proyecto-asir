#!/bin/bash

# Variables requeridas
# $repoApp = Repositorio que contiene el código de la api a desplegar
# $appName = Nombre del proyecto o api

# Cargar variables de entorno
set -e

fetchApp(){
    # Desactiva verificación de certificados
    git config --global http.sslverify false

    cd /
    git clone $repoApp
    cd /$appName
}

buildApp(){
    # Instalación de dependencias 
    npm i && npm run build
}

deployApp(){
    npm i -g pm2
    pm2 start npm --name "adt-frontend" -- run start
}

main(){
    fetchApp
    buildApp
    deployApp
    tail -f /dev/null
}

main