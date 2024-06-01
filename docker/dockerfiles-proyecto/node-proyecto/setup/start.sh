#!/bin/bash

# Script estándar

# Cargar variables de entorno y funciones
set -e
source /root/setup/libraries.sh

# Configuración del servicio SSH + Acceso remoto usuario + inicio del servicio SSH
config_ssh

# Mantener contenedor en ejecución
tail -f /dev/null

