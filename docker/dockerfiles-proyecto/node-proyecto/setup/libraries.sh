#!/bin/bash

# Variables de entorno
# ${HOME} - Variable que contiene el home de usuario actual

# Variables externas obligatorias provenientes del dockerfile o del docker-compose
# ${id_rsa} - El archivo que contiene la clave rsa

# Comandos/utilidades utilizados
# echo
# cat
# tail
# service

# Cargar variables de entorno
set -e

# Añadir la clave rsa al home del usuario administrador
config_ssh(){
    if [ -d ${HOME}/.ssh ]; then
        cat /root/setup/${id_rsa} >> ${HOME}/.ssh/authorized_keys
        echo 'ID RSA establecida en authorized_keys'
    else
        echo "El directorio $HOME/.ssh no existe, no se añade la clave rsa"
    fi

    # Iniciar servicio SSH
    service ssh start
}

setup_nestjs(){
    # Actualización de npm y instalación de la línea de comandos de NestJS
    npm update -g npm && npm i -g @nestjs/cli
}