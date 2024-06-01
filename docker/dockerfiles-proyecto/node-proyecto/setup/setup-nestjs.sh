#!/bin/bash

# Script para marco de trabajo con NestJS

# Cargar variables de entorno y funciones
set -e
source /root/setup/libraries.sh

# Configuración del servicio SSH + Acceso remoto usuario + inicio del servicio SSH
config_ssh

# Instalación de NestJS
setup_nestjs

# Mantener contenedor en ejecución
tail -f /dev/null

