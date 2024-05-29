#!/bin/bash

# Variables externas obligatorias provenientes del dockerfile o del docker-compose
# ${HOME} - Variable que contiene el home de usuario actual
# ${id_rsa} - El archivo que contiene la clave rsa

# Comandos/utilidades utilizados
# echo
# cat
# tail
# service

# Cargar variables de entorno
set -e

# Añadir la clave rsa al home del usuario administrador
if [ -f ${HOME}/.ssh ]; then
    cat /root/setup/${id_rsa} >> ${HOME}/.ssh/authorized_keys
    echo 'ID RSA establecida en authorized_keys'
else
    echo "El directorio $HOME/.ssh, no se añade la clave rsa"
fi

# Iniciar servicio SSH
service ssh start

# Mantener contenedor en ejecución
tail -f /dev/null