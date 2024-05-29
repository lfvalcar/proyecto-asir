#!/bin/bash

# Variables de entorno
# ${HOME} - Variable que contiene el home de usuario actual

# Comandos/utilidades utilizados
# sed
# echo
# mkdir

# Cargar variables de entorno
set -e

# Comprobar si existe el archivo de confguración del servicio SSH
if [ -f /etc/ssh/sshd_config ]; then
    # Permitir la conexión de ssh a root
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    # En caso de bloqueo, un tiempo de espera de 5m para volver
    sed -i 's/#LoginGraceTime 2m/LoginGraceTime 10m/g' /etc/ssh/sshd_config
    # Un máximo de 3 conexiones activas ssh
    sed -i 's/#MaxSessions 10/MaxSessions 5/g' /etc/ssh/sshd_config
    # Un máximo de 3 intentos fallidos de autenticación
    sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/g' /etc/ssh/sshd_config 
    # Se permite la autenticación mediante clave pública
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    echo '/etc/ssh/sshd_config configurado'

    # Comprobar si existe el directorio /var/run/sshd
    if [ ! -d /var/run/sshd ]; then
        # Creamos el directorio para le demonio en ejecución del servicio SSH
        mkdir -v /var/run/sshd 
    fi

    # Comprobar si existe el directorio .ssh en el home del usuario administrador para depositar la clave rsa
    if [ ! -d ${HOME}/.ssh ]; then
        # Crear el directorio .ssh en el usuario administrador
        mkdir -v ${HOME}/.ssh
    fi
else 
    return 1
fi