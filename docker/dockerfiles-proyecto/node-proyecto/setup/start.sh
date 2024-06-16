#!/bin/bash

# Variables de entorno
# ${HOME} - Variable que contiene el home de usuario actual

# Variables externas obligatorias provenientes del dockerfile o del docker-compose
# ${id_rsa} - El archivo que contiene la clave rsa
# $repo - Repositorio del proyecto que utiliza node y npm como gestor de paquetes

# Comandos/utilidades utilizados
# echo
# cat
# tail
# service
# npm
# cd

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

npm_depends(){
    # Actualización de npm y instalación de dependencias del repositorio del proyecto
    npm update -g npm
}

main(){
    # Configuración del servicio SSH + Acceso remoto usuario + inicio del servicio SSH
    config_ssh

    # Actualización y instalación de dependencias del repositorio
    npm_depends

    # Mantener contenedor en ejecución
    tail -f /dev/null
}

main
